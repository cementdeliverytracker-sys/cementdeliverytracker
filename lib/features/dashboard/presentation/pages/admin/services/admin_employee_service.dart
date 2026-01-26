import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cementdeliverytracker/core/constants/app_constants.dart';

/// Service class for admin-specific employee operations in Firestore.
/// This service handles employee approval, rejection, and retrieval for admin users.
class AdminEmployeeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate a unique 6-digit employee ID with collision avoidance.
  /// Attempts up to 10 times to find an unused ID before falling back.
  Future<String> generateUniqueEmployeeId() async {
    const min = 100000;
    const max = 999999;
    final rand = Random.secure();

    for (int i = 0; i < 10; i++) {
      final candidate = (min + rand.nextInt(max - min + 1)).toString();
      final clash = await _firestore
          .collection(AppConstants.usersCollection)
          .where('employeeId', isEqualTo: candidate)
          .limit(1)
          .get();
      if (clash.docs.isEmpty) {
        return candidate;
      }
    }

    return (min + rand.nextInt(max - min + 1)).toString();
  }

  /// Approve a pending employee and assign them an employee ID.
  /// Updates their userType to 'employee' and records approval timestamp.
  Future<void> approveEmployee(String userId) async {
    final employeeId = await generateUniqueEmployeeId();

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({
          'userType': AppConstants.userTypeEmployee,
          'employeeId': employeeId,
          'employeeRequestData.status': 'approved',
          'employeeRequestData.approvedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  /// Reject a pending employee request.
  /// Reverts their userType and removes request-specific data.
  Future<void> rejectEmployee(String userId) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({
          'userType': AppConstants.userTypeTempEmployee,
          'employeeRequestData': FieldValue.delete(),
          'adminId': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  /// Remove an approved employee and send them back to the approval queue.
  /// Converts the user to pending_employee, clears their employeeId, and keeps the adminId for re-approval.
  Future<void> removeEmployee({
    required String userId,
    required String adminId,
  }) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({
          'userType': AppConstants.userTypePendingEmployee,
          'adminId': adminId,
          'employeeId': FieldValue.delete(),
          'employeeRequestData': {
            'status': 'pending',
            'requestedAt': FieldValue.serverTimestamp(),
            'reason': 'removed_by_admin',
          },
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  /// Get a stream of all approved employees for a specific admin.
  /// Used to display the employee list in the admin dashboard.
  Stream<QuerySnapshot<Map<String, dynamic>>> getEmployeesStream(
    String adminId,
  ) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .where('userType', isEqualTo: AppConstants.userTypeEmployee)
        .where('adminId', isEqualTo: adminId)
        .snapshots();
  }

  /// Get a stream of pending employee requests for a specific admin.
  /// Real-time updates for approval workflow.
  Stream<QuerySnapshot<Map<String, dynamic>>> getPendingEmployeesStream(
    String adminId,
  ) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .where('userType', isEqualTo: AppConstants.userTypePendingEmployee)
        .where('adminId', isEqualTo: adminId)
        .snapshots();
  }

  /// Get all pending employees across all admins (for debugging purposes).
  /// Used in development to troubleshoot pending employee queries.
  Future<QuerySnapshot<Map<String, dynamic>>> getAllPendingEmployees() {
    return _firestore
        .collection(AppConstants.usersCollection)
        .where('userType', isEqualTo: AppConstants.userTypePendingEmployee)
        .get();
  }

  /// Log off all employees for a specific admin.
  /// Sets status to 'logged_out' for all approved employees.
  Future<void> logoffAllEmployees(String adminId) async {
    final employees = await _firestore
        .collection(AppConstants.usersCollection)
        .where('userType', isEqualTo: AppConstants.userTypeEmployee)
        .where('adminId', isEqualTo: adminId)
        .get();

    final batch = _firestore.batch();
    for (var doc in employees.docs) {
      batch.update(doc.reference, {
        'status': 'logged_out',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}
