import 'package:cementdeliverytracker/core/errors/failures.dart';
import 'package:cementdeliverytracker/features/orders/data/datasources/order_remote_data_source.dart';
import 'package:cementdeliverytracker/features/orders/data/models/order_model.dart';
import 'package:cementdeliverytracker/features/orders/domain/entities/order.dart'
    as entities;
import 'package:cementdeliverytracker/features/orders/domain/repositories/order_repository.dart';
import 'package:dartz/dartz.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource remoteDataSource;

  OrderRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, String>> createOrder(entities.Order order) async {
    try {
      final orderModel = OrderModel.fromEntity(order);
      final orderId = await remoteDataSource.createOrder(orderModel);
      return Right(orderId);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<entities.Order>>> getOrders(
    String adminId,
  ) async {
    try {
      final orders = await remoteDataSource.getOrders(adminId);
      return Right(orders);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, entities.Order>> getOrderById(String orderId) async {
    try {
      final order = await remoteDataSource.getOrderById(orderId);
      return Right(order);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateOrder(entities.Order order) async {
    try {
      final orderModel = OrderModel.fromEntity(order);
      await remoteDataSource.updateOrder(orderModel);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteOrder(String orderId) async {
    try {
      await remoteDataSource.deleteOrder(orderId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<List<entities.Order>> watchOrders(String adminId) {
    return remoteDataSource.watchOrders(adminId);
  }
}
