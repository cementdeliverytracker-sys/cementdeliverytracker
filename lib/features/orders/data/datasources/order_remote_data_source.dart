import 'package:cementdeliverytracker/features/orders/data/models/order_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class OrderRemoteDataSource {
  Future<String> createOrder(OrderModel order);
  Future<List<OrderModel>> getOrders(String adminId);
  Future<OrderModel> getOrderById(String orderId);
  Future<void> updateOrder(OrderModel order);
  Future<void> deleteOrder(String orderId);
  Stream<List<OrderModel>> watchOrders(String adminId);
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final FirebaseFirestore firestore;

  OrderRemoteDataSourceImpl({required this.firestore});

  @override
  Future<String> createOrder(OrderModel order) async {
    try {
      final docRef = await firestore.collection('orders').add(order.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  @override
  Future<List<OrderModel>> getOrders(String adminId) async {
    try {
      final querySnapshot = await firestore
          .collection('orders')
          .where('adminId', isEqualTo: adminId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => OrderModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get orders: $e');
    }
  }

  @override
  Future<OrderModel> getOrderById(String orderId) async {
    try {
      final docSnapshot = await firestore
          .collection('orders')
          .doc(orderId)
          .get();

      if (!docSnapshot.exists) {
        throw Exception('Order not found');
      }

      return OrderModel.fromJson(
        docSnapshot.data() as Map<String, dynamic>,
        docSnapshot.id,
      );
    } catch (e) {
      throw Exception('Failed to get order: $e');
    }
  }

  @override
  Future<void> updateOrder(OrderModel order) async {
    try {
      await firestore
          .collection('orders')
          .doc(order.id)
          .update(order.toJson()..remove('createdAt'));
    } catch (e) {
      throw Exception('Failed to update order: $e');
    }
  }

  @override
  Future<void> deleteOrder(String orderId) async {
    try {
      await firestore.collection('orders').doc(orderId).delete();
    } catch (e) {
      throw Exception('Failed to delete order: $e');
    }
  }

  @override
  Stream<List<OrderModel>> watchOrders(String adminId) {
    return firestore
        .collection('orders')
        .where('adminId', isEqualTo: adminId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => OrderModel.fromJson(doc.data(), doc.id))
              .toList(),
        );
  }
}
