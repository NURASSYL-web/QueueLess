import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:queue/src/features/auth/domain/auth_repository.dart';
import 'package:queue/src/shared/models/app_plan.dart';
import 'package:queue/src/shared/models/app_user.dart';
import 'package:queue/src/shared/models/user_role.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  }) : _auth = auth,
       _firestore = firestore;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  @override
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  @override
  Stream<AppUser?> watchProfile() {
    final current = currentUser;
    if (current == null) {
      return Stream.value(null);
    }

    return _users.doc(current.uid).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return AppUser.fromFirestore(snapshot);
    });
  }

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Future<AppUser?> getProfile() async {
    final user = currentUser;
    if (user == null) return null;
    final snapshot = await _users.doc(user.uid).get();
    if (!snapshot.exists) return null;
    return AppUser.fromFirestore(snapshot);
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    await _ensureUserDocument();
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final defaultPlan = AppPlans.defaultForRole(role);
    final user = AppUser(
      id: credential.user!.uid,
      email: email,
      role: role,
      planId: defaultPlan.id,
      planName: defaultPlan.name,
      planPriceTenge: defaultPlan.priceTenge,
      planStatus: defaultPlan.activationStatus,
    );

    await _users.doc(user.id).set({
      ...user.toMap(),
      'planId': defaultPlan.id,
      'planName': defaultPlan.name,
      'planPriceTenge': defaultPlan.priceTenge,
      'planStatus': defaultPlan.activationStatus,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> updatePushToken(String token) async {
    final user = currentUser;
    if (user == null) return;
    final existing = await getProfile();

    await _users.doc(user.uid).set({
      'email': user.email,
      'role': existing?.role.value ?? UserRole.regular.value,
      'pushToken': token,
      'planId': existing?.planId,
      'planName': existing?.planName,
      'planPriceTenge': existing?.planPriceTenge,
      'planStatus': existing?.planStatus,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> updatePlan({
    required String planId,
    required String planName,
    required int planPriceTenge,
    required String planStatus,
  }) async {
    final user = currentUser;
    if (user == null) return;

    await _users.doc(user.uid).set({
      'planId': planId,
      'planName': planName,
      'planPriceTenge': planPriceTenge,
      'planStatus': planStatus,
    }, SetOptions(merge: true));
  }

  Future<void> _ensureUserDocument() async {
    final user = currentUser;
    if (user == null) return;
    final existing = await getProfile();

    final defaultPlan = AppPlans.defaultForRole(
      existing?.role ?? UserRole.regular,
    );
    await _users.doc(user.uid).set({
      'email': user.email,
      'role': existing?.role.value ?? UserRole.regular.value,
      'planId': existing?.planId ?? defaultPlan.id,
      'planName': existing?.planName ?? defaultPlan.name,
      'planPriceTenge': existing?.planPriceTenge ?? defaultPlan.priceTenge,
      'planStatus': existing?.planStatus ?? defaultPlan.activationStatus,
    }, SetOptions(merge: true));
  }
}
