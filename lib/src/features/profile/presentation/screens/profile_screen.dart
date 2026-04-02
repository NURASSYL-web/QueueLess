import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:queue/src/core/constants/app_colors.dart';
import 'package:queue/src/core/widgets/brand_logo.dart';
import 'package:queue/src/features/auth/domain/auth_repository.dart';
import 'package:queue/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:queue/src/features/business/presentation/screens/business_dashboard_screen.dart';
import 'package:queue/src/features/business/presentation/screens/manage_place_screen.dart';
import 'package:queue/src/features/feedback/presentation/widgets/feedback_form_card.dart';
import 'package:queue/src/features/profile/presentation/screens/my_reports_screen.dart';
import 'package:queue/src/shared/models/app_plan.dart';
import 'package:queue/src/shared/models/app_user.dart';
import 'package:queue/src/shared/models/place.dart';
import 'package:queue/src/shared/repositories/firestore_places_repository.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepository = context.read<AuthRepository>();

    return StreamBuilder<AppUser?>(
      stream: authRepository.watchProfile(),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final currentUser = authRepository.currentUser;

        return Scaffold(
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF041523), AppColors.background],
              ),
            ),
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                children: [
                  const _ProfileHeader(),
                  const SizedBox(height: 24),
                  Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.accent, width: 3),
                        color: AppColors.surfaceRaised,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        ((profile?.email ?? currentUser?.email ?? 'Q')
                                .substring(0, 1))
                            .toUpperCase(),
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    profile?.email ?? currentUser?.email ?? 'QueueLess User',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    profile?.role.label ?? 'User',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'ROLE',
                          value: profile?.role.label ?? 'Unknown',
                          accent: AppColors.accentSoft,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _StatCard(
                          label: 'PLAN',
                          value: profile?.planName ?? 'No plan',
                          accent: AppColors.gold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _PlanOverviewCard(profile: profile),
                  const SizedBox(height: 18),
                  _ActionTile(
                    icon: Icons.analytics_outlined,
                    label: 'My Queue Reports',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const MyReportsScreen(),
                        ),
                      );
                    },
                  ),
                  if (profile?.isBusiness == true && currentUser != null) ...[
                    const SizedBox(height: 12),
                    _BusinessSection(ownerId: currentUser.uid),
                  ],
                  if (profile != null) ...[
                    const SizedBox(height: 14),
                    _PlanSection(profile: profile),
                  ],
                  const SizedBox(height: 16),
                  const FeedbackFormCard(),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: () => context.read<AuthController>().signOut(),
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.red,
                    ),
                    label: const Text('Logout'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFFC4C4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PlanOverviewCard extends StatelessWidget {
  const _PlanOverviewCard({required this.profile});

  final AppUser? profile;

  @override
  Widget build(BuildContext context) {
    if (profile == null) {
      return const SizedBox.shrink();
    }

    final isDemo = profile!.planStatus == 'demo';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF102638), Color(0xFF17324A)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              profile!.isBusiness
                  ? Icons.storefront_rounded
                  : Icons.workspace_premium_rounded,
              color: AppColors.accentSoft,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile!.planName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  profile!.planPriceTenge == 0
                      ? 'Current access: free'
                      : 'Current access: ${profile!.planPriceTenge} ₸ / month',
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: (isDemo ? AppColors.gold : AppColors.green).withValues(
                alpha: 0.16,
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              isDemo ? 'DEMO' : 'ACTIVE',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: isDemo ? AppColors.gold : AppColors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessSection extends StatelessWidget {
  const _BusinessSection({required this.ownerId});

  final String ownerId;

  @override
  Widget build(BuildContext context) {
    final placesRepository = context.read<FirestorePlacesRepository>();

    return StreamBuilder<List<Place>>(
      stream: placesRepository.watchOwnerPlaces(ownerId),
      builder: (context, snapshot) {
        final ownPlaces = snapshot.data ?? const <Place>[];

        return Column(
          children: [
            _ActionTile(
              icon: Icons.store_mall_directory_outlined,
              label: ownPlaces.isEmpty ? 'Create Business Place' : 'Open Business Dashboard',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => BusinessDashboardScreen(ownerId: ownerId),
                  ),
                );
              },
            ),
            if (ownPlaces.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ownPlaces.first.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('Live on map: Yes'),
                    Text('Phone: ${ownPlaces.first.phone}'),
                    Text('Instagram: ${ownPlaces.first.instagram}'),
                    Text('Category: ${ownPlaces.first.category.label}'),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ManagePlaceScreen(
                                ownerId: ownerId,
                                place: ownPlaces.first,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text('Quick edit place'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _PlanSection extends StatelessWidget {
  const _PlanSection({required this.profile});

  final AppUser profile;

  @override
  Widget build(BuildContext context) {
    final plans = AppPlans.forRole(profile.role);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Update Plan',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 12),
        ...plans.map(
          (plan) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PlanTile(profile: profile, plan: plan),
          ),
        ),
      ],
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({required this.profile, required this.plan});

  final AppUser profile;
  final AppPlan plan;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<AuthController>();
    final isCurrent = profile.planId == plan.id;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: plan.isPopular
              ? AppColors.accent.withValues(alpha: 0.7)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(plan.name, style: Theme.of(context).textTheme.titleMedium),
              ),
              if (plan.badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    plan.badge!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.accentSoft,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(plan.tagline),
          const SizedBox(height: 12),
          Text(
            plan.isFree
                ? plan.billingLabel
                : '${plan.priceTenge} ₸ ${plan.billingLabel}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: plan.role == profile.role ? AppColors.gold : AppColors.accent,
            ),
          ),
          const SizedBox(height: 12),
          ...plan.features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: AppColors.accentSoft,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(feature)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: isCurrent
                ? OutlinedButton(
                    onPressed: null,
                    child: const Text('Current plan'),
                  )
                : ElevatedButton(
                    onPressed: () async {
                      final success = await controller.updatePlan(
                        planId: plan.id,
                        planName: plan.name,
                        planPriceTenge: plan.priceTenge,
                        planStatus: plan.activationStatus,
                      );

                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? '${plan.name} activated in demo mode.'
                                : controller.error ?? 'Could not update plan',
                          ),
                        ),
                      );
                    },
                    child: Text(
                      profile.isBusiness && plan.id == AppPlans.businessDemo.id
                          ? 'Activate 490 ₸ demo'
                          : 'Choose ${plan.name}',
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

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
            'Profile',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.accentSoft),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: accent),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.accentSoft),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(label)),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
