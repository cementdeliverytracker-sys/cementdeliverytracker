import 'package:cementdeliverytracker/core/errors/failures.dart';
import 'package:cementdeliverytracker/core/network/network_info.dart';
import 'package:cementdeliverytracker/features/dashboard/data/datasources/employee_remote_data_source.dart';
import 'package:cementdeliverytracker/features/dashboard/domain/repositories/employee_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

/// Implementation of EmployeeRepository.
/// Handles employee management operations with error handling.
class EmployeeRepositoryImpl implements EmployeeRepository {
  final EmployeeRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  EmployeeRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, void>> approveEmployee({
    required String userId,
    required String adminId,
  }) async {
    if (!(await networkInfo.isConnected)) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      await remoteDataSource.approveEmployee(userId: userId, adminId: adminId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> rejectEmployee(String userId) async {
    if (!(await networkInfo.isConnected)) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      await remoteDataSource.rejectEmployee(userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeEmployee({
    required String userId,
    required String adminId,
  }) async {
    if (!(await networkInfo.isConnected)) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      await remoteDataSource.removeEmployee(userId: userId, adminId: adminId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, QuerySnapshot<Map<String, dynamic>>>>
  getEmployeesStream(String adminId) {
    try {
      return remoteDataSource
          .getEmployeesStream(adminId)
          .map((snapshot) => Right(snapshot));
    } catch (e) {
      return Stream.value(Left(ServerFailure(e.toString())));
    }
  }

  @override
  Stream<Either<Failure, QuerySnapshot<Map<String, dynamic>>>>
  getPendingEmployeesStream(String adminId) {
    try {
      return remoteDataSource
          .getPendingEmployeesStream(adminId)
          .map((snapshot) => Right(snapshot));
    } catch (e) {
      return Stream.value(Left(ServerFailure(e.toString())));
    }
  }

  @override
  Future<Either<Failure, void>> logoffAllEmployees(String adminId) async {
    if (!(await networkInfo.isConnected)) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      await remoteDataSource.logoffAllEmployees(adminId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
