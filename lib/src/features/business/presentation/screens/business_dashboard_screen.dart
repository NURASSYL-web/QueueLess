import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:queue/src/core/constants/app_colors.dart';
import 'package:queue/src/core/widgets/loading_view.dart';
import 'package:queue/src/core/utils/time_formatter.dart';
import 'package:queue/src/features/business/presentation/screens/manage_place_screen.dart';
import 'package:queue/src/features/queue/presentation/widgets/queue_update_sheet.dart';
import 'package:queue/src/shared/models/place.dart';
import 'package:queue/src/shared/models/place_queue_summary.dart';
import 'package:queue/src/shared/models/queue_level.dart';
import 'package:queue/src/shared/models/queue_report.dart';
import 'package:queue/src/shared/repositories/firestore_places_repository.dart';
import 'package:queue/src/shared/repositories/firestore_queue_repository.dart';

class BusinessDashboardScreen extends StatelessWidget {
  const BusinessDashboardScreen({super.key, required this.ownerId});

  final String ownerId;

  @override
  Widget build(BuildContext context) {
    final placesRepository = context.read<FirestorePlacesRepository>();

    return StreamBuilder<List<Place>>(
      stream: placesRepository.watchOwnerPlaces(ownerId),
      builder: (context, snapshot) {
        final places = snapshot.data ?? const <Place>[];
        final place = places.isEmpty ? null : places.first;

        return Scaffold(
          appBar: AppBar(title: const Text('Business Dashboard')),
          body: place == null
              ? _BusinessEmptyState(ownerId: ownerId)
              : _BusinessDashboardBody(ownerId: ownerId, place: place),
        );
      },
    );
  }
}

class _BusinessEmptyState extends StatelessWidget {
  const _BusinessEmptyState({required this.ownerId});

  final String ownerId;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF102638), Color(0xFF17324A)],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Set up your business place',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Add your branch to QueueLess so nearby people can discover your queue status, contact details, and live updates.',
              ),
              const SizedBox(height: 20),
              ...const [
                'Publish your place on the live map',
                'Show short queue moments to attract foot traffic',
                'Prepare your analytics and recommendations feed',
              ].map(
                (point) => Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.accentSoft,
                        size: 18,
                      ),
                      SizedBox(width: 10),
                      Expanded(child: Text(point)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ManagePlaceScreen(ownerId: ownerId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_business_rounded),
                  label: const Text('Create my place'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BusinessDashboardBody extends StatelessWidget {
  const _BusinessDashboardBody({required this.ownerId, required this.place});

  final String ownerId;
  final Place place;

  @override
  Widget build(BuildContext context) {
    final queueRepository = context.read<FirestoreQueueRepository>();

    return StreamBuilder<List<PlaceQueueSummary>>(
      stream: queueRepository.watchDashboard([place]),
      builder: (context, summarySnapshot) {
        if (!summarySnapshot.hasData) {
          return const LoadingView(label: 'Loading business insights...');
        }

        final summary = summarySnapshot.data!.first;

        return StreamBuilder<List<QueueReport>>(
          stream: queueRepository.watchPlaceReports(place.id),
          builder: (context, reportsSnapshot) {
            final reports = reportsSnapshot.data ?? const <QueueReport>[];
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                _BusinessHeroCard(place: place, summary: summary),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _BusinessMetricCard(
                        label: 'Queue now',
                        value: summary.queueLevel.label,
                        accent: summary.queueLevel.color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _BusinessMetricCard(
                        label: 'Wait time',
                        value: '${summary.estimatedMinutes} min',
                        accent: AppColors.gold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _BusinessMetricCard(
                        label: 'Recent reports',
                        value: '${summary.reportCount}',
                        accent: AppColors.accentSoft,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _BusinessMetricCard(
                        label: 'Crowd level',
                        value: summary.crowdLevel,
                        accent: AppColors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _BusinessActions(place: place),
                const SizedBox(height: 16),
                _BusinessInsightCard(summary: summary, reports: reports),
                const SizedBox(height: 16),
                _BusinessContactCard(place: place),
                const SizedBox(height: 16),
                _RecentReportsCard(reports: reports),
              ],
            );
          },
        );
      },
    );
  }
}

class _BusinessHeroCard extends StatelessWidget {
  const _BusinessHeroCard({required this.place, required this.summary});

  final Place place;
  final PlaceQueueSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF102638), Color(0xFF17324A)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  place.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: summary.queueLevel.color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  summary.queueLevel.label.toUpperCase(),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: summary.queueLevel.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${place.category.label} • Last updated ${TimeFormatter.queueWindowLabel(summary.lastUpdated)}',
          ),
          const SizedBox(height: 14),
          Text(
            'Your business is live in QueueLess discovery. Keep the queue updated and short moments will convert into more nearby traffic.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _BusinessMetricCard extends StatelessWidget {
  const _BusinessMetricCard({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessActions extends StatelessWidget {
  const _BusinessActions({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick actions', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    QueueUpdateSheet.show(
                      context,
                      placeId: place.id,
                      placeName: place.name,
                    );
                  },
                  icon: const Icon(Icons.bolt_rounded),
                  label: const Text('Update queue'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ManagePlaceScreen(
                          ownerId: place.ownerId,
                          place: place,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Edit place'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BusinessInsightCard extends StatelessWidget {
  const _BusinessInsightCard({
    required this.summary,
    required this.reports,
  });

  final PlaceQueueSummary summary;
  final List<QueueReport> reports;

  @override
  Widget build(BuildContext context) {
    final shortCount = reports
        .where((report) => report.queueLevel == QueueLevel.short)
        .length;
    final recommendation = summary.queueLevel == QueueLevel.short
        ? 'Push this short queue window in your stories. You are in a high-conversion moment.'
        : summary.queueLevel == QueueLevel.medium
        ? 'Keep updates fresh. One more short report can improve your local attractiveness.'
        : 'Queue is long now. Encourage off-peak visits and update again when traffic drops.';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Business insight',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          Text(recommendation),
          const SizedBox(height: 16),
          Text(
            'Short reports in recent activity: $shortCount / ${reports.length}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _BusinessContactCard extends StatelessWidget {
  const _BusinessContactCard({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Business profile', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 14),
          _InfoRow(label: 'Phone', value: place.phone),
          _InfoRow(label: 'Instagram', value: place.instagram),
          _InfoRow(
            label: 'Map pin',
            value:
                '${place.latitude.toStringAsFixed(4)}, ${place.longitude.toStringAsFixed(4)}',
          ),
        ],
      ),
    );
  }
}

class _RecentReportsCard extends StatelessWidget {
  const _RecentReportsCard({required this.reports});

  final List<QueueReport> reports;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent queue activity',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 14),
          if (reports.isEmpty)
            Text(
              'No queue updates yet. Use "Update queue" to create the first signal for your business.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            ...reports.take(5).map(
              (report) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: report.queueLevel.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${report.queueLevel.label} queue • ${TimeFormatter.queueWindowLabel(report.timestamp)}',
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(child: Text(value.isEmpty ? 'Not set yet' : value)),
        ],
      ),
    );
  }
}
