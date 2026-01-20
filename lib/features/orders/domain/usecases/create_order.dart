import 'package:cementdeliverytracker/core/errors/failures.dart';
import 'package:cementdeliverytracker/features/orders/domain/entities/order.dart'
    as entities;
import 'package:cementdeliverytracker/features/orders/domain/repositories/order_repository.dart';
import 'package:dartz/dartz.dart';

class CreateOrder {
  final OrderRepository repository;

  CreateOrder(this.repository);

  Future<Either<Failure, String>> call(entities.Order order) {
    return repository.createOrder(order);
  }
}
