import 'package:firebase_auth/firebase_auth.dart';
import 'package:queue/src/shared/models/app_user.dart';
import 'package:queue/src/shared/models/user_role.dart';

abstract class AuthRepository {
  Stream<User?> authStateChanges();
  Stream<AppUser?> watchProfile();

  User? get currentUser;

  Future<AppUser?> getProfile();

  Future<void> signIn({required String email, required String password});

  Future<void> signUp({
    required String email,
    required String password,
    required UserRole role,
  });

  Future<void> signOut();

  Future<void> updatePushToken(String token);

  Future<void> updatePlan({
    required String planId,
    required String planName,
    required int planPriceTenge,
    required String planStatus,
  });
}
