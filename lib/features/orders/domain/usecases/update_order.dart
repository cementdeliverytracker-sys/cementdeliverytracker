import 'package:cementdeliverytracker/core/errors/failures.dart';
import 'package:cementdeliverytracker/features/orders/domain/entities/order.dart'
    as entities;
import 'package:cementdeliverytracker/features/orders/domain/repositories/order_repository.dart';
import 'package:dartz/dartz.dart';

class UpdateOrder {
  final OrderRepository repository;

  UpdateOrder(this.repository);

  Future<Either<Failure, void>> call(entities.Order order) {
    return repository.updateOrder(order);
  }
}
