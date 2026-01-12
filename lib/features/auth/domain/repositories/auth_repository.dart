import 'package:cementdeliverytracker/core/errors/failures.dart';
import 'package:cementdeliverytracker/features/auth/domain/entities/auth_entities.dart';
import 'package:dartz/dartz.dart';
import 'package:cementdeliverytracker/features/auth/domain/usecases/change_password_params.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthUser>> login(LoginParams params);
  Future<Either<Failure, AuthUser>> signup(SignupParams params);
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, void>> changePassword(ChangePasswordParams params);
  Stream<AuthUser?> get authStateChanges;
  AuthUser? get currentUser;
}
