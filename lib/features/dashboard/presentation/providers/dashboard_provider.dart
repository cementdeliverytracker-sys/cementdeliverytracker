import 'package:cementdeliverytracker/core/errors/failures.dart';
import 'package:cementdeliverytracker/features/dashboard/domain/entities/dashboard_entities.dart';
import 'package:cementdeliverytracker/features/dashboard/domain/usecases/dashboard_usecases.dart';
import 'package:flutter/material.dart';

enum DashboardState { initial, loading, loaded, error }

class DashboardProvider extends ChangeNotifier {
  final GetUserDashboardDataUseCase getUserDashboardDataUseCase;
  final ApproveUserUseCase approveUserUseCase;
  final GetPendingUsersUseCase getPendingUsersUseCase;

  DashboardState _state = DashboardState.initial;
  DashboardData? _userData;
  List<DashboardData> _pendingUsers = [];
  String? _errorMessage;

  DashboardProvider({
    required this.getUserDashboardDataUseCase,
    required this.approveUserUseCase,
    required this.getPendingUsersUseCase,
  });

  DashboardState get state => _state;
  DashboardData? get userData => _userData;
  List<DashboardData> get pendingUsers => _pendingUsers;
  String? get errorMessage => _errorMessage;

  Future<void> loadUserData(String userId) async {
    _state = DashboardState.loading;
    notifyListeners();

    final result = await getUserDashboardDataUseCase(userId);

    result.fold(
      (failure) {
        _state = DashboardState.error;
        _errorMessage = _mapFailureToMessage(failure);
        notifyListeners();
      },
      (data) {
        _userData = data;
        _state = DashboardState.loaded;
        _errorMessage = null;
        notifyListeners();
      },
    );
  }

  Future<void> approveUser(String userId) async {
    final result = await approveUserUseCase(userId);

    result.fold(
      (failure) {
        _errorMessage = _mapFailureToMessage(failure);
        notifyListeners();
      },
      (_) {
        // Remove the approved user from pending list
        _pendingUsers.removeWhere((user) => user.userId == userId);
        notifyListeners();
      },
    );
  }

  void listenToPendingUsers() {
    getPendingUsersUseCase().listen((result) {
      result.fold(
        (failure) {
          _errorMessage = _mapFailureToMessage(failure);
          notifyListeners();
        },
        (users) {
          _pendingUsers = users;
          notifyListeners();
        },
      );
    });
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is NetworkFailure) {
      return 'Network error: ${failure.message}';
    } else if (failure is ServerFailure) {
      return 'Server error: ${failure.message}';
    } else {
      return 'An unexpected error occurred';
    }
  }
}
