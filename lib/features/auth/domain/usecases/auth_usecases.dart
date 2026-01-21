import 'package:cementdeliverytracker/core/errors/failures.dart';
import 'package:cementdeliverytracker/features/auth/domain/entities/auth_entities.dart';
import 'package:cementdeliverytracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:cementdeliverytracker/features/auth/domain/usecases/change_password_params.dart';
import 'package:dartz/dartz.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<Either<Failure, AuthUser>> call(LoginParams params) {
    return repository.login(params);
  }
}

class SignupUseCase {
  final AuthRepository repository;

  SignupUseCase(this.repository);

  Future<Either<Failure, AuthUser>> call(SignupParams params) {
    return repository.signup(params);
  }
}

class LogoutUseCase {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  Future<Either<Failure, void>> call() {
    return repository.logout();
  }
}

class GetAuthStateUseCase {
  final AuthRepository repository;

  GetAuthStateUseCase(this.repository);

  Stream<AuthUser?> call() {
    return repository.authStateChanges;
  }
}

class GetCurrentUserUseCase {
  final AuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  AuthUser? call() {
    return repository.currentUser;
  }
}

class ChangePasswordUseCase {
  final AuthRepository repository;

  ChangePasswordUseCase(this.repository);

  Future<Either<Failure, void>> call(ChangePasswordParams params) {
    return repository.changePassword(params);
  }
}

class GetUserProfileUseCase {
  final AuthRepository repository;

  GetUserProfileUseCase(this.repository);

  Future<Either<Failure, UserProfile?>> call(String userId) {
    return repository.getUserProfile(userId);
  }
}

class EnsureEmployeeIdUseCase {
  final AuthRepository repository;

  EnsureEmployeeIdUseCase(this.repository);

  Future<Either<Failure, UserProfile>> call(String userId) {
    return repository.ensureEmployeeId(userId);
  }
}

class SubmitEmployeeJoinRequestUseCase {
  final AuthRepository repository;

  SubmitEmployeeJoinRequestUseCase(this.repository);

  Future<Either<Failure, String>> call(String userId, String adminCode) {
    return repository.submitEmployeeJoinRequest(userId, adminCode);
  }
}

class SubmitAdminRequestUseCase {
  final AuthRepository repository;

  SubmitAdminRequestUseCase(this.repository);

  Future<Either<Failure, void>> call(String userId, String companyName) {
    return repository.submitAdminRequest(userId, companyName);
  }
}
