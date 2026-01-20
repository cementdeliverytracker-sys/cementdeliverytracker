import 'dart:math';

import 'package:cementdeliverytracker/core/constants/app_constants.dart';
import 'package:cementdeliverytracker/core/errors/failures.dart';
import 'package:cementdeliverytracker/features/auth/domain/entities/auth_entities.dart';
import 'package:cementdeliverytracker/features/auth/domain/usecases/auth_usecases.dart';
import 'package:cementdeliverytracker/features/auth/domain/usecases/change_password_params.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthNotifier extends ChangeNotifier {
  final LoginUseCase loginUseCase;
  final SignupUseCase signupUseCase;
  final LogoutUseCase logoutUseCase;
  final GetAuthStateUseCase getAuthStateUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final ChangePasswordUseCase changePasswordUseCase;

  AuthState _state = AuthState.initial;
  AuthUser? _user;
  String? _errorMessage;

  AuthNotifier({
    required this.loginUseCase,
    required this.signupUseCase,
    required this.logoutUseCase,
    required this.getAuthStateUseCase,
    required this.getCurrentUserUseCase,
    required this.changePasswordUseCase,
  }) {
    _initializeAuthState();
  }

  AuthState get state => _state;
  AuthUser? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _state == AuthState.authenticated;

  Stream<AuthUser?> get authStateChanges => getAuthStateUseCase();

  void _initializeAuthState() {
    getAuthStateUseCase().listen((user) async {
      if (user != null) {
        _user = user;
        _state = AuthState.authenticated;
        await _ensureEmployeeId(user.id);
      } else {
        _user = null;
        _state = AuthState.unauthenticated;
      }
      _errorMessage = null;
      notifyListeners();
    });
  }

  Future<void> login(String email, String password) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    final params = LoginParams(email: email, password: password);
    final result = await loginUseCase(params);

    await result.fold(
      (failure) async {
        _state = AuthState.error;
        _errorMessage = _mapFailureToMessage(failure);
        notifyListeners();
        // Propagate FirebaseAuthException for UI error handling
        if (failure is AuthFailure) {
          final msg = failure.message.toLowerCase();
          if (msg.contains('no user') || msg.contains('not found')) {
            throw FirebaseAuthException(
              code: 'user-not-found',
              message: failure.message,
            );
          } else if (msg.contains('wrong password') ||
              msg.contains('incorrect password')) {
            throw FirebaseAuthException(
              code: 'wrong-password',
              message: failure.message,
            );
          } else if (msg.contains('network')) {
            throw FirebaseAuthException(
              code: 'network-request-failed',
              message: failure.message,
            );
          } else {
            throw FirebaseAuthException(
              code: 'unknown',
              message: failure.message,
            );
          }
        } else if (failure is NetworkFailure) {
          throw FirebaseAuthException(
            code: 'network-request-failed',
            message: failure.message,
          );
        } else {
          throw FirebaseAuthException(
            code: 'unknown',
            message: failure.message,
          );
        }
      },
      (user) async {
        _user = user;
        _state = AuthState.authenticated;
        _errorMessage = null;
        await _ensureEmployeeId(user.id);
        notifyListeners();
      },
    );
  }

  Future<void> signup({
    required String email,
    required String password,
    required String username,
    String? phone,
    String? imagePath,
  }) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    final params = SignupParams(
      email: email,
      password: password,
      username: username,
      phone: phone,
      imagePath: imagePath,
    );
    final result = await signupUseCase(params);

    result.fold(
      (failure) {
        _state = AuthState.error;
        _errorMessage = _mapFailureToMessage(failure);
        notifyListeners();
      },
      (user) {
        _user = user;
        _state = AuthState.authenticated;
        _errorMessage = null;
        _ensureEmployeeId(user.id);
        notifyListeners();
      },
    );
  }

  Future<void> logout() async {
    _state = AuthState.loading;
    notifyListeners();

    final result = await logoutUseCase();

    result.fold(
      (failure) {
        _state = AuthState.error;
        _errorMessage = _mapFailureToMessage(failure);
        notifyListeners();
      },
      (_) {
        _user = null;
        _state = AuthState.unauthenticated;
        _errorMessage = null;
        notifyListeners();
      },
    );
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    final params = ChangePasswordParams(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    final result = await changePasswordUseCase(params);

    result.fold(
      (failure) {
        _state = AuthState.error;
        _errorMessage = _mapFailureToMessage(failure);
        notifyListeners();
      },
      (_) {
        _state = AuthState.authenticated;
        _errorMessage = null;
        notifyListeners();
      },
    );
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is AuthFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return 'Network error: ${failure.message}';
    } else if (failure is ServerFailure) {
      return 'Server error: ${failure.message}';
    } else {
      return 'An unexpected error occurred';
    }
  }

  Future<void> _ensureEmployeeId(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      final data = userDoc.data();
      if (data == null) return;

      final userType = data['userType'] as String?;
      if (userType != AppConstants.userTypeEmployee) return;

      final existingId = (data['employeeId'] ?? '') as String;
      if (existingId.trim().isNotEmpty) return;

      final newId = await _generateUniqueEmployeeId();

      await userDoc.reference.set({
        'employeeId': newId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Silent failure; employee will just lack ID until next login triggers retry.
    }
  }

  Future<String> _generateUniqueEmployeeId() async {
    const min = 100000;
    const max = 999999;
    final rand = Random.secure();

    for (int i = 0; i < 10; i++) {
      final candidate = (min + rand.nextInt(max - min + 1)).toString();
      final clash = await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .where('employeeId', isEqualTo: candidate)
          .limit(1)
          .get();
      if (clash.docs.isEmpty) {
        return candidate;
      }
    }

    // Fallback: allow last generated value even if uniqueness check exceeded attempts.
    return (min + rand.nextInt(max - min + 1)).toString();
  }
}
