import 'package:cementdeliverytracker/core/errors/failures.dart';
import 'package:cementdeliverytracker/core/network/network_info.dart';
import 'package:cementdeliverytracker/features/dashboard/data/datasources/distributor_remote_data_source.dart';
import 'package:cementdeliverytracker/features/dashboard/domain/repositories/distributor_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

/// Implementation of DistributorRepository.
/// Handles distributor management operations with error handling.
class DistributorRepositoryImpl implements DistributorRepository {
  final DistributorRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  DistributorRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Stream<Either<Failure, QuerySnapshot<Map<String, dynamic>>>>
  getDistributorsStream(String adminId) {
    try {
      return remoteDataSource
          .getDistributorsStream(adminId)
          .map((snapshot) => Right(snapshot));
    } catch (e) {
      return Stream.value(Left(ServerFailure(e.toString())));
    }
  }

  @override
  Future<Either<Failure, void>> addDistributor({
    required String adminId,
    required String name,
    String? phone,
    String? email,
    String? location,
    String? region,
    double? latitude,
    double? longitude,
    String? createdByUserId,
    String? createdByName,
    String? createdByType,
  }) async {
    if (!(await networkInfo.isConnected)) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      await remoteDataSource.addDistributor(
        adminId: adminId,
        name: name,
        phone: phone,
        email: email,
        location: location,
        region: region,
        latitude: latitude,
        longitude: longitude,
        createdByUserId: createdByUserId,
        createdByName: createdByName,
        createdByType: createdByType,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateDistributor({
    required String distributorId,
    required String name,
    String? phone,
    String? email,
    String? location,
    String? region,
    double? latitude,
    double? longitude,
  }) async {
    if (!(await networkInfo.isConnected)) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      await remoteDataSource.updateDistributor(
        distributorId: distributorId,
        name: name,
        phone: phone,
        email: email,
        location: location,
        region: region,
        latitude: latitude,
        longitude: longitude,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteDistributor(String distributorId) async {
    if (!(await networkInfo.isConnected)) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      await remoteDataSource.deleteDistributor(distributorId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
