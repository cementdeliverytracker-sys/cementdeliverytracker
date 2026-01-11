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
      );
    } catch (e) {
      throw ServerFailure('Failed to fetch user data: ${e.toString()}');
    }
  }

  @override
  Future<void> approveUser(String userId) async {
    try {
      await firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({'userType': AppConstants.userTypeAdmin});
    } catch (e) {
      throw ServerFailure('Failed to approve user: ${e.toString()}');
    }
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
            );
          }).toList();
        });
  }
}
