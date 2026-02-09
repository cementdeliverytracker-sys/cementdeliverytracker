import 'package:cementdeliverytracker/core/errors/failures.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

/// Repository interface for employee management operations.
/// Defines contracts for employee-related business logic.
abstract class EmployeeRepository {
  /// Approve a pending employee request
  Future<Either<Failure, void>> approveEmployee({
    required String userId,
    required String adminId,
  });

  /// Reject a pending employee request
  Future<Either<Failure, void>> rejectEmployee(String userId);

  /// Remove an approved employee
  Future<Either<Failure, void>> removeEmployee({
    required String userId,
    required String adminId,
  });

  /// Get stream of approved employees for an admin
  Stream<Either<Failure, QuerySnapshot<Map<String, dynamic>>>>
  getEmployeesStream(String adminId);

  /// Get stream of pending employee requests for an admin
  Stream<Either<Failure, QuerySnapshot<Map<String, dynamic>>>>
  getPendingEmployeesStream(String adminId);

  /// Log off all employees for a specific admin
  Future<Either<Failure, void>> logoffAllEmployees(String adminId);
}
