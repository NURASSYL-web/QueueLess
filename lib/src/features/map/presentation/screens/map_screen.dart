import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:queue/src/core/constants/app_constants.dart';
import 'package:queue/src/core/constants/app_colors.dart';
import 'package:queue/src/core/widgets/brand_logo.dart';
import 'package:queue/src/core/widgets/error_view.dart';
import 'package:queue/src/core/widgets/loading_view.dart';
import 'package:queue/src/features/home/presentation/controllers/home_controller.dart';
import 'package:queue/src/features/queue/presentation/widgets/queue_update_sheet.dart';
import 'package:queue/src/shared/models/place_queue_summary.dart';
import 'package:queue/src/shared/repositories/firestore_places_repository.dart';
import 'package:queue/src/shared/repositories/firestore_queue_repository.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final placesRepository = context.read<FirestorePlacesRepository>();
    final queueRepository = context.read<FirestoreQueueRepository>();

    return StreamBuilder(
      stream: placesRepository.watchPlaces(),
      builder: (context, placesSnapshot) {
        if (placesSnapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Map')),
            body: ErrorView(message: placesSnapshot.error.toString()),
          );
        }

        if (!placesSnapshot.hasData) {
          return const Scaffold(body: LoadingView());
        }

        return Consumer<HomeController>(
          builder: (context, controller, _) {
            return StreamBuilder<List<PlaceQueueSummary>>(
              stream: queueRepository.watchDashboard(placesSnapshot.data!),
              builder: (context, dashboardSnapshot) {
                if (dashboardSnapshot.hasError) {
                  return Scaffold(
                    appBar: AppBar(title: const Text('Map')),
                    body: ErrorView(
                      message: dashboardSnapshot.error.toString(),
                    ),
                  );
                }

                if (!dashboardSnapshot.hasData) {
                  return const Scaffold(
                    body: LoadingView(label: 'Loading map...'),
                  );
                }

                final summaries = controller.enrichAndFilter(
                  dashboardSnapshot.data!,
                );

                return _MapView(summaries: summaries);
              },
            );
          },
        );
      },
    );
  }
}

class _MapView extends StatefulWidget {
  const _MapView({required this.summaries});

  final List<PlaceQueueSummary> summaries;

  @override
  State<_MapView> createState() => _MapViewState();
}

class _MapViewState extends State<_MapView> {
  final Completer<GoogleMapController> _controller = Completer();
  final Map<String, BitmapDescriptor> _markerIconCache = {};
  bool _centeredOnUser = false;

  @override
  Widget build(BuildContext context) {
    final homeController = context.watch<HomeController>();
    final userPosition = homeController.userPosition;

    return Scaffold(
      body: Stack(
        children: [
          FutureBuilder<Set<Marker>>(
            future: _buildMarkers(userPosition),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const LoadingView(label: 'Preparing map markers...');
              }

              final circles = <Circle>{};
              if (userPosition != null) {
                circles.add(_buildUserCircle(userPosition));
                _focusOnUserIfNeeded(userPosition);
              }

              return GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(
                    AppConstants.tarazLatitude,
                    AppConstants.tarazLongitude,
                  ),
                  zoom: AppConstants.defaultMapZoom,
                ),
                myLocationButtonEnabled: false,
                myLocationEnabled: false,
                markers: snapshot.data!,
                circles: circles,
                onMapCreated: (controller) {
                  if (!_controller.isCompleted) {
                    _controller.complete(controller);
                  }
                },
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.ink700.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const BrandLogo(height: 32),
                        const Spacer(),
                        Text(
                          'Activity',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _MapFloatingButton(
                        icon: Icons.my_location_rounded,
                        label: userPosition == null ? 'Find me' : 'My location',
                        onTap: () async {
                          await homeController.loadUserLocation();
                          final refreshedPosition = homeController.userPosition;
                          if (refreshedPosition != null) {
                            _centeredOnUser = true;
                            final mapController = await _controller.future;
                            await mapController.animateCamera(
                              CameraUpdate.newCameraPosition(
                                CameraPosition(
                                  target: LatLng(
                                    refreshedPosition.latitude,
                                    refreshedPosition.longitude,
                                  ),
                                  zoom: 14.5,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 10),
                      _MapFloatingButton(
                        icon: Icons.layers_rounded,
                        label: '${widget.summaries.length} places',
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: _QueueLegend(),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<Set<Marker>> _buildMarkers(Position? userPosition) async {
    final markers = <Marker>{};

    for (final summary in widget.summaries) {
      markers.add(
        Marker(
          markerId: MarkerId(summary.place.id),
          position: summary.place.latLng,
          icon: await _markerIconFor(summary),
          infoWindow: InfoWindow(
            title: summary.place.name,
            snippet:
                '${summary.queueLevel.label} • ~${summary.estimatedMinutes} min',
            onTap: () => _showPlaceSheet(context, summary),
          ),
          onTap: () => _showPlaceSheet(context, summary),
        ),
      );
    }

    if (userPosition != null) {
      markers.add(_buildUserMarker(userPosition));
    }

    return markers;
  }

  Future<BitmapDescriptor> _markerIconFor(PlaceQueueSummary summary) async {
    final key =
        '${summary.queueLevel.value}_${summary.estimatedMinutes}_${summary.hasRecentReports}';
    final cached = _markerIconCache[key];
    if (cached != null) return cached;

    final icon = BitmapDescriptor.bytes(
      await _buildMarkerBytes(
        label: '${summary.estimatedMinutes}m',
        color: summary.queueLevel.color,
        tinted: summary.hasRecentReports,
      ),
    );
    _markerIconCache[key] = icon;
    return icon;
  }

  Future<Uint8List> _buildMarkerBytes({
    required String label,
    required Color color,
    required bool tinted,
  }) async {
    const width = 110.0;
    const height = 70.0;
    const bubbleHeight = 40.0;
    const radius = 16.0;
    const pointerWidth = 20.0;
    const pointerHeight = 16.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = tinted ? color : AppColors.green;
    final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.18);
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final bubbleRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, width, bubbleHeight),
      const Radius.circular(radius),
    );

    canvas.drawRRect(bubbleRect.shift(const Offset(0, 6)), shadowPaint);
    canvas.drawRRect(bubbleRect, paint);
    canvas.drawRRect(bubbleRect, borderPaint);

    final pointerPath = Path()
      ..moveTo((width - pointerWidth) / 2, bubbleHeight - 2)
      ..lineTo(width / 2, bubbleHeight + pointerHeight)
      ..lineTo((width + pointerWidth) / 2, bubbleHeight - 2)
      ..close();

    canvas.drawPath(
      pointerPath.shift(const Offset(0, 6)),
      shadowPaint,
    );
    canvas.drawPath(pointerPath, paint);
    canvas.drawPath(pointerPath, borderPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        (width - textPainter.width) / 2,
        (bubbleHeight - textPainter.height) / 2,
      ),
    );

    final image = await recorder.endRecording().toImage(
      width.toInt(),
      height.toInt(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  Marker _buildUserMarker(Position userPosition) {
    return Marker(
      markerId: const MarkerId('current_user'),
      position: LatLng(userPosition.latitude, userPosition.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      infoWindow: const InfoWindow(
        title: 'You are here',
        snippet: 'Current location',
      ),
      zIndexInt: 10,
    );
  }

  Circle _buildUserCircle(Position userPosition) {
    return Circle(
      circleId: const CircleId('current_user_radius'),
      center: LatLng(userPosition.latitude, userPosition.longitude),
      radius: 180,
      fillColor: AppColors.accent.withValues(alpha: 0.12),
      strokeColor: AppColors.accentSoft,
      strokeWidth: 2,
    );
  }

  Future<void> _focusOnUserIfNeeded(Position userPosition) async {
    if (_centeredOnUser || !_controller.isCompleted) return;

    _centeredOnUser = true;
    final mapController = await _controller.future;
    await mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(userPosition.latitude, userPosition.longitude),
          zoom: 13.6,
        ),
      ),
    );
  }

  Future<void> _showPlaceSheet(
    BuildContext context,
    PlaceQueueSummary summary,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.place.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MapStatusChip(
                      label: summary.hasRecentReports
                          ? '${summary.queueLevel.label} queue'
                          : 'Short queue',
                      color: summary.queueLevel.color,
                    ),
                    _MapStatusChip(
                      label: '${summary.crowdLevel} crowd',
                      color: AppColors.accentSoft,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  summary.hasRecentReports
                      ? '${summary.place.category.label} • averaged from ${summary.reportCount} recent report${summary.reportCount == 1 ? '' : 's'}'
                      : '${summary.place.category.label} • no recent reports yet',
                ),
                const SizedBox(height: 8),
                Text('Estimated wait: ${summary.estimatedMinutes} min'),
                if (summary.distanceKm != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Distance: ${summary.distanceKm!.toStringAsFixed(1)} km',
                  ),
                ],
                const SizedBox(height: 6),
                Text('Phone: ${summary.place.phone}'),
                Text('Instagram: ${summary.place.instagram}'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    QueueUpdateSheet.show(
                      context,
                      placeId: summary.place.id,
                      placeName: summary.place.name,
                    );
                  },
                  child: const Text('Update Queue'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QueueLegend extends StatelessWidget {
  const _QueueLegend();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.ink700.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Wrap(
          spacing: 10,
          runSpacing: 8,
          children: const [
            _LegendItem(label: 'Short', color: AppColors.green),
            _LegendItem(label: 'Medium', color: AppColors.yellow),
            _LegendItem(label: 'Long', color: AppColors.red),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _MapStatusChip extends StatelessWidget {
  const _MapStatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MapFloatingButton extends StatelessWidget {
  const _MapFloatingButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.ink700.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AppColors.accentSoft),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
