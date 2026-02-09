import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cementdeliverytracker/core/constants/app_constants.dart';

/// Remote data source for employee-related operations.
/// Handles direct Firestore operations for employee management.
abstract class EmployeeRemoteDataSource {
  Future<String> generateUniqueEmployeeId(String adminId);
  Future<void> approveEmployee({
    required String userId,
    required String adminId,
  });
  Future<void> rejectEmployee(String userId);
  Future<void> removeEmployee({
    required String userId,
    required String adminId,
  });
  Stream<QuerySnapshot<Map<String, dynamic>>> getEmployeesStream(
    String adminId,
  );
  Stream<QuerySnapshot<Map<String, dynamic>>> getPendingEmployeesStream(
    String adminId,
  );
  Future<void> logoffAllEmployees(String adminId);
}

class EmployeeRemoteDataSourceImpl implements EmployeeRemoteDataSource {
  final FirebaseFirestore firestore;

  EmployeeRemoteDataSourceImpl({required this.firestore});

  @override
  Future<String> generateUniqueEmployeeId(String adminId) async {
    const min = 100000;
    const max = 999999;
    final rand = Random.secure();

    for (int i = 0; i < 10; i++) {
      final candidate = (min + rand.nextInt(max - min + 1)).toString();
      final clash = await firestore
          .collection(AppConstants.usersCollection)
          .where('adminId', isEqualTo: adminId)
          .where('employeeId', isEqualTo: candidate)
          .limit(1)
          .get();
      if (clash.docs.isEmpty) {
        return candidate;
      }
    }

    return (min + rand.nextInt(max - min + 1)).toString();
  }

  @override
  Future<void> approveEmployee({
    required String userId,
    required String adminId,
  }) async {
    final employeeId = await generateUniqueEmployeeId(adminId);

    await firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({
          'userType': AppConstants.userTypeEmployee,
          'adminId': adminId,
          'employeeId': employeeId,
          'employeeRequestData.status': 'approved',
          'employeeRequestData.approvedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  @override
  Future<void> rejectEmployee(String userId) async {
    await firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({
          'userType': AppConstants.userTypeTempEmployee,
          'employeeRequestData': FieldValue.delete(),
          'adminId': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  @override
  Future<void> removeEmployee({
    required String userId,
    required String adminId,
  }) async {
    await firestore.collection(AppConstants.usersCollection).doc(userId).update(
      {
        'userType': AppConstants.userTypePendingEmployee,
        'adminId': adminId,
        'employeeId': FieldValue.delete(),
        'employeeRequestData': {
          'status': 'pending',
          'requestedAt': FieldValue.serverTimestamp(),
          'reason': 'removed_by_admin',
        },
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> getEmployeesStream(
    String adminId,
  ) {
    return firestore
        .collection(AppConstants.usersCollection)
        .where('userType', isEqualTo: AppConstants.userTypeEmployee)
        .where('adminId', isEqualTo: adminId)
        .snapshots();
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> getPendingEmployeesStream(
    String adminId,
  ) {
    return firestore
        .collection(AppConstants.usersCollection)
        .where('userType', isEqualTo: AppConstants.userTypePendingEmployee)
        .where('adminId', isEqualTo: adminId)
        .snapshots();
  }

  @override
  Future<void> logoffAllEmployees(String adminId) async {
    final employees = await firestore
        .collection(AppConstants.usersCollection)
        .where('userType', isEqualTo: AppConstants.userTypeEmployee)
        .where('adminId', isEqualTo: adminId)
        .get();

    final batch = firestore.batch();
    for (var doc in employees.docs) {
      batch.update(doc.reference, {
        'status': 'logged_out',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}
