import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:queue/src/shared/models/app_plan.dart';
import 'package:queue/src/shared/models/user_role.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.role,
    this.pushToken,
    this.shortQueueSubscriptions = const {},
    required this.planId,
    required this.planName,
    required this.planPriceTenge,
    required this.planStatus,
  });

  final String id;
  final String email;
  final UserRole role;
  final String? pushToken;
  final Map<String, dynamic> shortQueueSubscriptions;
  final String planId;
  final String planName;
  final int planPriceTenge;
  final String planStatus;

  bool get isBusiness => role == UserRole.business;
  bool get hasPaidPlan => planPriceTenge > 0;
  AppPlan get currentPlan => AppPlans.fromId(planId, role);
  int get businessPlaceLimit => currentPlan.maxBusinessPlaces;

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role.value,
      'pushToken': pushToken,
      'shortQueueSubscriptions': shortQueueSubscriptions,
      'planId': planId,
      'planName': planName,
      'planPriceTenge': planPriceTenge,
      'planStatus': planStatus,
    };
  }

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final role = UserRole.fromValue(data['role'] as String?);
    final defaultPlan = AppPlans.defaultForRole(role);
    return AppUser(
      id: doc.id,
      email: data['email'] as String? ?? '',
      role: role,
      pushToken: data['pushToken'] as String?,
      shortQueueSubscriptions:
          data['shortQueueSubscriptions'] as Map<String, dynamic>? ?? const {},
      planId: data['planId'] as String? ?? defaultPlan.id,
      planName: data['planName'] as String? ?? defaultPlan.name,
      planPriceTenge: data['planPriceTenge'] as int? ?? defaultPlan.priceTenge,
      planStatus: data['planStatus'] as String? ?? defaultPlan.activationStatus,
    );
  }
}
