import 'package:cementdeliverytracker/core/errors/failures.dart';
import 'package:cementdeliverytracker/features/auth/domain/entities/auth_entities.dart';
import 'package:cementdeliverytracker/features/auth/domain/usecases/auth_usecases.dart';
import 'package:cementdeliverytracker/features/auth/domain/usecases/change_password_params.dart';
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
  final GetUserProfileUseCase getUserProfileUseCase;
  final EnsureEmployeeIdUseCase ensureEmployeeIdUseCase;
  final SubmitEmployeeJoinRequestUseCase submitEmployeeJoinRequestUseCase;
  final SubmitAdminRequestUseCase submitAdminRequestUseCase;

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
    required this.getUserProfileUseCase,
    required this.ensureEmployeeIdUseCase,
    required this.submitEmployeeJoinRequestUseCase,
    required this.submitAdminRequestUseCase,
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
        await _ensureEmployeeIdIfNeeded(user.id);
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
        await _ensureEmployeeIdIfNeeded(user.id);
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
        _ensureEmployeeIdIfNeeded(user.id);
        notifyListeners();
      },
    );
  }

  Future<UserProfile?> loadUserProfile(String userId) async {
    final result = await getUserProfileUseCase(userId);

    return result.fold((failure) {
      _errorMessage ??= _mapFailureToMessage(failure);
      return null;
    }, (profile) => profile);
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

  Future<void> _ensureEmployeeIdIfNeeded(String userId) async {
    final result = await ensureEmployeeIdUseCase(userId);

    result.fold((failure) {
      // Failure is intentionally silent to avoid blocking login; retry on next auth event.
      _errorMessage ??= _mapFailureToMessage(failure);
    }, (_) {});
  }

  Future<String?> submitEmployeeJoinRequest(String adminCode) async {
    if (_user == null) {
      _errorMessage = 'Not authenticated';
      notifyListeners();
      return null;
    }

    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await submitEmployeeJoinRequestUseCase(_user!.id, adminCode);

    return result.fold(
      (failure) {
        _state = AuthState.error;
        _errorMessage = _mapFailureToMessage(failure);
        notifyListeners();
        return null;
      },
      (adminId) {
        _state = AuthState.authenticated;
        notifyListeners();
        return adminId;
      },
    );
  }

  Future<bool> submitAdminRequest(String companyName) async {
    if (_user == null) {
      _errorMessage = 'Not authenticated';
      notifyListeners();
      return false;
    }

    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await submitAdminRequestUseCase(_user!.id, companyName);

    return result.fold(
      (failure) {
        _state = AuthState.error;
        _errorMessage = _mapFailureToMessage(failure);
        notifyListeners();
        return false;
      },
      (_) {
        _state = AuthState.authenticated;
        notifyListeners();
        return true;
      },
    );
  }
}
