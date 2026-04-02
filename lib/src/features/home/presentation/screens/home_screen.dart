import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:queue/src/core/constants/app_colors.dart';
import 'package:queue/src/core/widgets/brand_logo.dart';
import 'package:queue/src/core/widgets/empty_state_view.dart';
import 'package:queue/src/core/widgets/error_view.dart';
import 'package:queue/src/core/widgets/loading_view.dart';
import 'package:queue/src/features/home/presentation/controllers/home_controller.dart';
import 'package:queue/src/features/home/presentation/widgets/place_card.dart';
import 'package:queue/src/features/queue/presentation/widgets/queue_update_sheet.dart';
import 'package:queue/src/shared/models/place_category.dart';
import 'package:queue/src/shared/models/place_queue_summary.dart';
import 'package:queue/src/shared/models/queue_level.dart';
import 'package:queue/src/shared/repositories/firestore_places_repository.dart';
import 'package:queue/src/shared/repositories/firestore_queue_repository.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final placesRepository = context.read<FirestorePlacesRepository>();
    final queueRepository = context.read<FirestoreQueueRepository>();

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF071626), AppColors.background],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder(
            stream: placesRepository.watchPlaces(),
            builder: (context, placesSnapshot) {
              if (placesSnapshot.hasError) {
                return ErrorView(message: placesSnapshot.error.toString());
              }
              if (!placesSnapshot.hasData) {
                return const LoadingView();
              }

              return Consumer<HomeController>(
                builder: (context, controller, _) {
                  return StreamBuilder<List<PlaceQueueSummary>>(
                    stream: queueRepository.watchDashboard(
                      placesSnapshot.data!,
                    ),
                    builder: (context, dashboardSnapshot) {
                      if (dashboardSnapshot.hasError) {
                        return ErrorView(
                          message: dashboardSnapshot.error.toString(),
                        );
                      }
                      if (!dashboardSnapshot.hasData) {
                        return const LoadingView(
                          label: 'Building live queue feed...',
                        );
                      }

                      final filtered = controller.enrichAndFilter(
                        dashboardSnapshot.data!,
                      );

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                        children: [
                          const _ListTopBar(),
                          const SizedBox(height: 26),
                          Text(
                            'Nearby Places',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 18),
                          _FilterStrip(controller: controller),
                          const SizedBox(height: 18),
                          if (filtered.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 40),
                              child: EmptyStateView(
                                title: 'No places match these filters',
                                subtitle:
                                    'Try a wider distance or remove some queue filters.',
                              ),
                            )
                          else
                            ...filtered.map(
                              (summary) => PlaceCard(
                                summary: summary,
                                onUpdateTap: () => QueueUpdateSheet.show(
                                  context,
                                  placeId: summary.place.id,
                                  placeName: summary.place.name,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ListTopBar extends StatelessWidget {
  const _ListTopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.ink700,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const BrandLogo(height: 30),
          const SizedBox(width: 12),
          Text(
            'Live Queue Feed',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.accentSoft),
          ),
          const Spacer(),
          const Icon(Icons.tune_rounded, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _FilterStrip extends StatelessWidget {
  const _FilterStrip({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ChoiceChip(
                  label: const Text('All'),
                  selected: controller.selectedCategory == null,
                  onSelected: (_) => controller.selectCategory(null),
                ),
              ),
              for (final category in PlaceCategory.values)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    label: Text(category.label),
                    selected: controller.selectedCategory == category,
                    onSelected: (_) => controller.selectCategory(category),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final level in QueueLevel.values)
              ChoiceChip(
                label: Text(level.label),
                selected: controller.queueFilter == level,
                onSelected: (_) => controller.selectQueueFilter(
                  controller.queueFilter == level ? null : level,
                ),
              ),
            FilterChip(
              label: const Text('Updated recently'),
              selected: controller.recentlyUpdatedOnly,
              onSelected: controller.toggleRecentlyUpdated,
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: DistanceFilter.values
                .map(
                  (filter) => Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ChoiceChip(
                      label: Text(filter.label),
                      selected: controller.distanceFilter == filter,
                      onSelected: (_) =>
                          controller.selectDistanceFilter(filter),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
