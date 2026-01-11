import 'package:cementdeliverytracker/core/errors/failures.dart';
import 'package:cementdeliverytracker/features/auth/domain/entities/auth_entities.dart';
import 'package:cementdeliverytracker/features/auth/domain/usecases/auth_usecases.dart';
import 'package:flutter/material.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthNotifier extends ChangeNotifier {
  final LoginUseCase loginUseCase;
  final SignupUseCase signupUseCase;
  final LogoutUseCase logoutUseCase;
  final GetAuthStateUseCase getAuthStateUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;

  AuthState _state = AuthState.initial;
  AuthUser? _user;
  String? _errorMessage;

  AuthNotifier({
    required this.loginUseCase,
    required this.signupUseCase,
    required this.logoutUseCase,
    required this.getAuthStateUseCase,
    required this.getCurrentUserUseCase,
  }) {
    _initializeAuthState();
  }

  AuthState get state => _state;
  AuthUser? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _state == AuthState.authenticated;

  Stream<AuthUser?> get authStateChanges => getAuthStateUseCase();

  void _initializeAuthState() {
    getAuthStateUseCase().listen((user) {
      if (user != null) {
        _user = user;
        _state = AuthState.authenticated;
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
}
