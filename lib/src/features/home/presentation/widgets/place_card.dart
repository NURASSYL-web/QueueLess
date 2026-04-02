import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:queue/src/core/constants/app_colors.dart';
import 'package:queue/src/core/services/notification_preferences_repository.dart';
import 'package:queue/src/core/utils/time_formatter.dart';
import 'package:queue/src/shared/models/place_queue_summary.dart';

class PlaceCard extends StatelessWidget {
  const PlaceCard({
    super.key,
    required this.summary,
    required this.onUpdateTap,
  });

  final PlaceQueueSummary summary;
  final VoidCallback onUpdateTap;

  @override
  Widget build(BuildContext context) {
    final queueLevel = summary.queueLevel;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  _iconForCategory(summary.place.category.label),
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(summary.place.name, style: textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      summary.distanceKm == null
                          ? summary.place.category.label
                          : '${summary.place.category.label} • ${summary.distanceKm!.toStringAsFixed(1)} km away',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    TimeFormatter.formatEstimatedTime(summary.estimatedMinutes),
                    style: textTheme.titleLarge?.copyWith(
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('EST. WAIT', style: textTheme.bodySmall),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _Badge(
                label: '${queueLevel.label.toUpperCase()} QUEUE',
                color: queueLevel.color,
              ),
              const SizedBox(width: 10),
              _Badge(
                label: '${summary.crowdLevel.toUpperCase()} CROWD',
                color: AppColors.accentSoft,
              ),
              const Spacer(),
              Text(
                TimeFormatter.queueWindowLabel(summary.lastUpdated),
                style: textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Wait Time',
                  value: TimeFormatter.formatEstimatedTime(
                    summary.estimatedMinutes,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricTile(
                  label: 'Reports',
                  value: summary.reportCount.toString(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onUpdateTap,
                  child: const Text('Update'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    try {
                      await context
                          .read<NotificationPreferencesRepository>()
                          .setShortQueueAlert(
                            placeId: summary.place.id,
                            enabled: true,
                          );
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            kIsWeb
                                ? 'Alert saved for ${summary.place.name}. Push delivery is fully available on mobile.'
                                : 'Alerts enabled for ${summary.place.name}',
                          ),
                        ),
                      );
                    } catch (error) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Could not enable alerts right now: $error',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Notify'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'coffee':
        return Icons.local_cafe_rounded;
      case 'banks':
        return Icons.account_balance_rounded;
      case 'clinics':
        return Icons.local_hospital_rounded;
      default:
        return Icons.restaurant_rounded;
    }
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.surfaceRaised,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(letterSpacing: 1.1),
          ),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
