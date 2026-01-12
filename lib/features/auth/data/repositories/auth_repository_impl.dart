import 'package:cementdeliverytracker/core/errors/failures.dart';
import 'package:cementdeliverytracker/core/network/network_info.dart';
import 'package:cementdeliverytracker/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:cementdeliverytracker/features/auth/domain/entities/auth_entities.dart';
import 'package:cementdeliverytracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cementdeliverytracker/features/auth/domain/usecases/change_password_params.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, AuthUser>> login(LoginParams params) async {
    if (!(await networkInfo.isConnected)) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final result = await remoteDataSource.login(params);
      return Right(result);
    } on FirebaseAuthException catch (e) {
      rethrow; // Let the UI handle this
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthUser>> signup(SignupParams params) async {
    if (!(await networkInfo.isConnected)) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final result = await remoteDataSource.signup(params);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> changePassword(
    ChangePasswordParams params,
  ) async {
    try {
      await remoteDataSource.changePassword(params);
      return const Right(null);
    } catch (e) {
      if (e is Failure) {
        return Left(e);
      }
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<AuthUser?> get authStateChanges => remoteDataSource.authStateChanges;

  @override
  AuthUser? get currentUser => remoteDataSource.currentUser;
}
