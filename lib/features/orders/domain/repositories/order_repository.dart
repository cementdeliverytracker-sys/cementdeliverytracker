import 'package:cementdeliverytracker/core/errors/failures.dart';
import 'package:cementdeliverytracker/features/orders/domain/entities/order.dart'
    as entities;
import 'package:dartz/dartz.dart';

abstract class OrderRepository {
  Future<Either<Failure, String>> createOrder(entities.Order order);
  Future<Either<Failure, List<entities.Order>>> getOrders(String adminId);
  Future<Either<Failure, entities.Order>> getOrderById(String orderId);
  Future<Either<Failure, void>> updateOrder(entities.Order order);
  Future<Either<Failure, void>> deleteOrder(String orderId);
  Stream<List<entities.Order>> watchOrders(String adminId);
}
