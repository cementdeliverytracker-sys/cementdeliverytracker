import 'package:cementdeliverytracker/core/errors/failures.dart';
import 'package:cementdeliverytracker/features/orders/domain/entities/order.dart'
    as entities;
import 'package:cementdeliverytracker/features/orders/domain/repositories/order_repository.dart';
import 'package:dartz/dartz.dart';

class GetOrders {
  final OrderRepository repository;

  GetOrders(this.repository);

  Future<Either<Failure, List<entities.Order>>> call(String adminId) {
    return repository.getOrders(adminId);
  }
}
