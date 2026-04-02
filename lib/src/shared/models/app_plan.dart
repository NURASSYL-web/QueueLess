import 'package:queue/src/shared/models/user_role.dart';

class AppPlan {
  const AppPlan({
    required this.id,
    required this.name,
    required this.role,
    required this.priceTenge,
    required this.billingLabel,
    required this.tagline,
    required this.features,
    this.badge,
    this.isPopular = false,
    this.activationStatus = 'active',
    this.maxBusinessPlaces = 0,
  });

  final String id;
  final String name;
  final UserRole role;
  final int priceTenge;
  final String billingLabel;
  final String tagline;
  final List<String> features;
  final String? badge;
  final bool isPopular;
  final String activationStatus;
  final int maxBusinessPlaces;

  bool get isFree => priceTenge == 0;
}

abstract final class AppPlans {
  static const AppPlan freeExplorer = AppPlan(
    id: 'free_explorer',
    name: 'Free Explorer',
    role: UserRole.regular,
    priceTenge: 0,
    billingLabel: 'Free forever',
    tagline: 'Live queue map and quick crowd updates for everyday use.',
    features: [
      'View live queues around Taraz',
      'Send short, medium, and long updates',
      'Basic nearby map discovery',
    ],
    badge: 'Starter',
  );

  static const AppPlan premiumPulse = AppPlan(
    id: 'premium_pulse',
    name: 'Premium Pulse',
    role: UserRole.regular,
    priceTenge: 990,
    billingLabel: 'per month',
    tagline: 'For users who want smarter alerts and favorite places.',
    features: [
      'Instant short-queue notifications',
      'Saved places and faster revisit flow',
      'Priority recommendations nearby',
    ],
    badge: 'Popular',
    isPopular: true,
  );

  static const AppPlan premiumPlus = AppPlan(
    id: 'premium_plus',
    name: 'Premium Plus',
    role: UserRole.regular,
    priceTenge: 1790,
    billingLabel: 'per month',
    tagline: 'Best for power users tracking multiple places every day.',
    features: [
      'Unlimited smart alerts',
      'Advanced queue trend hints',
      'Favorite collections and deeper insights',
    ],
  );

  static const AppPlan businessDemo = AppPlan(
    id: 'business_demo',
    name: 'Business Demo',
    role: UserRole.business,
    priceTenge: 490,
    billingLabel: 'demo access',
    tagline: 'Instant trial for cafés, banks, and clinics before launch.',
    features: [
      'Claim one place and manage queue status',
      'Receive customer traffic from QueueLess',
      'Preview basic business analytics widgets',
    ],
    badge: 'Demo',
    activationStatus: 'demo',
    maxBusinessPlaces: 1,
  );

  static const AppPlan businessStart = AppPlan(
    id: 'business_start',
    name: 'Business Start',
    role: UserRole.business,
    priceTenge: 2490,
    billingLabel: 'per month',
    tagline: 'For one branch that wants better visibility and conversions.',
    features: [
      'Own and edit your business place',
      'Priority placement for nearby customers',
      'Basic conversion and visit analytics',
    ],
    badge: 'Best Value',
    isPopular: true,
    maxBusinessPlaces: 1,
  );

  static const AppPlan businessGrowth = AppPlan(
    id: 'business_growth',
    name: 'Business Growth',
    role: UserRole.business,
    priceTenge: 3990,
    billingLabel: 'per month',
    tagline: 'For active businesses optimizing queue quality and repeat visits.',
    features: [
      'Deeper queue analytics',
      'Recommendation boosts in local discovery',
      'Multi-campaign promo support',
    ],
    maxBusinessPlaces: 1,
  );

  static const AppPlan businessPro = AppPlan(
    id: 'business_pro',
    name: 'Business Pro',
    role: UserRole.business,
    priceTenge: 4990,
    billingLabel: 'per month',
    tagline: 'For high-traffic locations preparing for AI queue optimization.',
    features: [
      'Advanced demand insights',
      'Future AI traffic forecasting access',
      'Priority support and expansion-ready setup',
    ],
    maxBusinessPlaces: 5,
  );

  static List<AppPlan> forRole(UserRole role) {
    if (role == UserRole.business) {
      return const [businessDemo, businessStart, businessGrowth, businessPro];
    }

    return const [freeExplorer, premiumPulse, premiumPlus];
  }

  static AppPlan defaultForRole(UserRole role) {
    return role == UserRole.business ? businessDemo : freeExplorer;
  }

  static AppPlan fromId(String planId, UserRole role) {
    return forRole(role).firstWhere(
      (plan) => plan.id == planId,
      orElse: () => defaultForRole(role),
    );
  }
}
