import 'dart:math';

import 'package:cementdeliverytracker/core/constants/app_constants.dart';
import 'package:cementdeliverytracker/core/errors/failures.dart';
import 'package:cementdeliverytracker/features/dashboard/domain/entities/dashboard_entities.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardData> getUserDashboardData(String userId);
  Future<void> approveUser(String userId);
  Stream<List<DashboardData>> getPendingUsers();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final FirebaseFirestore firestore;
  final Random _random = Random.secure();

  DashboardRemoteDataSourceImpl({required this.firestore});

  @override
  Future<DashboardData> getUserDashboardData(String userId) async {
    try {
      final doc = await firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (!doc.exists) {
        throw ServerFailure('User not found');
      }

      final data = doc.data()!;
      return DashboardData(
        userId: doc.id,
        username: data['username'] ?? '',
        email: data['email'] ?? '',
        userType: data['userType'] ?? AppConstants.userTypePending,
        imageUrl: data['image_url'],
        phone: data['phone'],
        adminId: data['adminId'] as String?,
      );
    } catch (e) {
      throw ServerFailure('Failed to fetch user data: ${e.toString()}');
    }
  }

  @override
  Future<void> approveUser(String userId) async {
    try {
      final userRef = firestore
          .collection(AppConstants.usersCollection)
          .doc(userId);
      final snapshot = await userRef.get();

      if (!snapshot.exists) {
        throw ServerFailure('User not found');
      }

      final data = snapshot.data() ?? <String, dynamic>{};
      final existingAdminId = (data['adminId'] as String?)?.trim();
      final adminId = (existingAdminId != null && existingAdminId.isNotEmpty)
          ? existingAdminId
          : await _generateUniqueAdminId();

      await userRef.update({
        'userType': AppConstants.userTypeAdmin,
        'adminId': adminId,
        'adminRequestData.status': 'approved',
        'adminRequestData.approvedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ServerFailure('Failed to approve user: ${e.toString()}');
    }
  }

  Future<String> _generateUniqueAdminId() async {
    const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    String candidate;
    bool exists;

    do {
      candidate = List.generate(
        6,
        (_) => characters[_random.nextInt(characters.length)],
      ).join();

      final snapshot = await firestore
          .collection(AppConstants.usersCollection)
          .where('adminId', isEqualTo: candidate)
          .limit(1)
          .get();
      exists = snapshot.docs.isNotEmpty;
    } while (exists);

    return candidate;
  }

  @override
  Stream<List<DashboardData>> getPendingUsers() {
    return firestore
        .collection(AppConstants.usersCollection)
        .where('userType', isEqualTo: AppConstants.userTypePending)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return DashboardData(
              userId: doc.id,
              username: data['username'] ?? '',
              email: data['email'] ?? '',
              userType: data['userType'] ?? AppConstants.userTypePending,
              imageUrl: data['image_url'],
              phone: data['phone'],
              adminId: data['adminId'] as String?,
            );
          }).toList();
        });
  }
}
