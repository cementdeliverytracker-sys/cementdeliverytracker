import 'package:cementdeliverytracker/core/errors/failures.dart';
import 'package:cementdeliverytracker/core/network/network_info.dart';
import 'package:cementdeliverytracker/features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import 'package:cementdeliverytracker/features/dashboard/domain/entities/dashboard_entities.dart';
import 'package:cementdeliverytracker/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:dartz/dartz.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  DashboardRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, DashboardData>> getUserDashboardData(
    String userId,
  ) async {
    if (!(await networkInfo.isConnected)) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final result = await remoteDataSource.getUserDashboardData(userId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> approveUser(String userId) async {
    if (!(await networkInfo.isConnected)) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      await remoteDataSource.approveUser(userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<DashboardData>>> getPendingUsers() async* {
    final isConnected = await networkInfo.isConnected;
    if (!isConnected) {
      yield const Left(NetworkFailure('No internet connection'));
      return;
    }

    yield* remoteDataSource.getPendingUsers().map((users) => Right(users));
  }
}
