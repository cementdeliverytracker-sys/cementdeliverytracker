import 'package:cementdeliverytracker/core/errors/failures.dart';
import 'package:cementdeliverytracker/features/dashboard/domain/repositories/employee_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

/// Use case to approve a pending employee
class ApproveEmployeeUseCase {
  final EmployeeRepository repository;

  ApproveEmployeeUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String userId,
    required String adminId,
  }) {
    return repository.approveEmployee(userId: userId, adminId: adminId);
  }
}

/// Use case to reject a pending employee
class RejectEmployeeUseCase {
  final EmployeeRepository repository;

  RejectEmployeeUseCase(this.repository);

  Future<Either<Failure, void>> call(String userId) {
    return repository.rejectEmployee(userId);
  }
}

/// Use case to remove an approved employee
class RemoveEmployeeUseCase {
  final EmployeeRepository repository;

  RemoveEmployeeUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String userId,
    required String adminId,
  }) {
    return repository.removeEmployee(userId: userId, adminId: adminId);
  }
}

/// Use case to get stream of approved employees
class GetEmployeesStreamUseCase {
  final EmployeeRepository repository;

  GetEmployeesStreamUseCase(this.repository);

  Stream<Either<Failure, QuerySnapshot<Map<String, dynamic>>>> call(
    String adminId,
  ) {
    return repository.getEmployeesStream(adminId);
  }
}

/// Use case to get stream of pending employee requests
class GetPendingEmployeesStreamUseCase {
  final EmployeeRepository repository;

  GetPendingEmployeesStreamUseCase(this.repository);

  Stream<Either<Failure, QuerySnapshot<Map<String, dynamic>>>> call(
    String adminId,
  ) {
    return repository.getPendingEmployeesStream(adminId);
  }
}

/// Use case to log off all employees
class LogoffAllEmployeesUseCase {
  final EmployeeRepository repository;

  LogoffAllEmployeesUseCase(this.repository);

  Future<Either<Failure, void>> call(String adminId) {
    return repository.logoffAllEmployees(adminId);
  }
}
