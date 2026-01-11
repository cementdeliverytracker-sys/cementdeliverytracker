import 'package:cementdeliverytracker/core/errors/failures.dart';
import 'package:cementdeliverytracker/features/dashboard/domain/entities/dashboard_entities.dart';
import 'package:dartz/dartz.dart';

abstract class DashboardRepository {
  Future<Either<Failure, DashboardData>> getUserDashboardData(String userId);
  Future<Either<Failure, void>> approveUser(String userId);
  Stream<Either<Failure, List<DashboardData>>> getPendingUsers();
}
