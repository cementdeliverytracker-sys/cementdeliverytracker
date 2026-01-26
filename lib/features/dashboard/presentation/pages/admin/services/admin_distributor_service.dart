import 'package:cementdeliverytracker/core/constants/app_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service layer for managing distributors in Firestore.
/// Stores distributors per admin for add/view/edit/remove workflows.
class AdminDistributorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(AppConstants.distributorsCollection);

  Stream<QuerySnapshot<Map<String, dynamic>>> getDistributorsStream(
    String adminId,
  ) {
    return _collection
        .where('adminId', isEqualTo: adminId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> addDistributor({
    required String adminId,
    required String name,
    String? phone,
    String? email,
    String? location,
    String? region,
  }) {
    return _collection.add({
      'adminId': adminId,
      'name': name,
      'phone': phone,
      'email': email,
      'location': location,
      'region': region,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateDistributor({
    required String distributorId,
    required String name,
    String? phone,
    String? email,
    String? location,
    String? region,
  }) {
    return _collection.doc(distributorId).update({
      'name': name,
      'phone': phone,
      'email': email,
      'location': location,
      'region': region,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteDistributor(String distributorId) {
    return _collection.doc(distributorId).delete();
  }
}
