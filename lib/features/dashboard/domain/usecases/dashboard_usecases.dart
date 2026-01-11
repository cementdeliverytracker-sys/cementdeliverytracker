import 'package:cementdeliverytracker/core/errors/failures.dart';
import 'package:cementdeliverytracker/features/dashboard/domain/entities/dashboard_entities.dart';
import 'package:cementdeliverytracker/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:dartz/dartz.dart';

class GetUserDashboardDataUseCase {
  final DashboardRepository repository;

  GetUserDashboardDataUseCase(this.repository);

  Future<Either<Failure, DashboardData>> call(String userId) {
    return repository.getUserDashboardData(userId);
  }
}

class ApproveUserUseCase {
  final DashboardRepository repository;

  ApproveUserUseCase(this.repository);

  Future<Either<Failure, void>> call(String userId) {
    return repository.approveUser(userId);
  }
}

class GetPendingUsersUseCase {
  final DashboardRepository repository;

  GetPendingUsersUseCase(this.repository);

  Stream<Either<Failure, List<DashboardData>>> call() {
    return repository.getPendingUsers();
  }
}
