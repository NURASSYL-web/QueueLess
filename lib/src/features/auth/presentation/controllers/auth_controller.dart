import 'package:flutter/material.dart';
import 'package:queue/src/features/auth/domain/auth_repository.dart';
import 'package:queue/src/shared/models/user_role.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._repository);

  final AuthRepository _repository;

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> signIn({required String email, required String password}) async {
    return _perform(() => _repository.signIn(email: email, password: password));
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    return _perform(
      () => _repository.signUp(email: email, password: password, role: role),
    );
  }

  Future<void> signOut() => _repository.signOut();

  Future<bool> updatePlan({
    required String planId,
    required String planName,
    required int planPriceTenge,
    required String planStatus,
  }) async {
    return _perform(
      () => _repository.updatePlan(
        planId: planId,
        planName: planName,
        planPriceTenge: planPriceTenge,
        planStatus: planStatus,
      ),
    );
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> _perform(Future<void> Function() action) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await action();
      return true;
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
