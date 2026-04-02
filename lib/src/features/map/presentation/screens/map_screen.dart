import 'dart:async';

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
import 'package:queue/src/shared/models/queue_level.dart';
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
  bool _centeredOnUser = false;

  @override
  Widget build(BuildContext context) {
    final homeController = context.watch<HomeController>();
    final userPosition = homeController.userPosition;

    final markers = <Marker>{
      ...widget.summaries.map((summary) {
        return Marker(
          markerId: MarkerId(summary.place.id),
          position: summary.place.latLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(_markerHue(summary)),
          infoWindow: InfoWindow(
            title: summary.place.name,
            snippet:
                '${summary.queueLevel.label} • ~${summary.estimatedMinutes} min',
            onTap: () => _showPlaceSheet(context, summary),
          ),
          onTap: () => _showPlaceSheet(context, summary),
        );
      }),
    };

    final circles = <Circle>{};
    if (userPosition != null) {
      markers.add(_buildUserMarker(userPosition));
      circles.add(_buildUserCircle(userPosition));
      _focusOnUserIfNeeded(userPosition);
    }

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(
                AppConstants.tarazLatitude,
                AppConstants.tarazLongitude,
              ),
              zoom: AppConstants.defaultMapZoom,
            ),
            myLocationButtonEnabled: false,
            myLocationEnabled: false,
            markers: markers,
            circles: circles,
            onMapCreated: (controller) {
              if (!_controller.isCompleted) {
                _controller.complete(controller);
              }
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
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _markerHue(PlaceQueueSummary summary) {
    switch (summary.queueLevel) {
      case QueueLevel.short:
        return BitmapDescriptor.hueGreen;
      case QueueLevel.medium:
        return BitmapDescriptor.hueYellow;
      case QueueLevel.long:
        return BitmapDescriptor.hueRed;
    }
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
                Text(
                  '${summary.place.category.label} • ${summary.queueLevel.label} queue • ${summary.crowdLevel} crowd',
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
