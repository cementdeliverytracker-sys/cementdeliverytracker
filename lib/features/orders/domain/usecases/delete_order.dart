import 'package:cementdeliverytracker/core/errors/failures.dart';
import 'package:cementdeliverytracker/features/orders/domain/repositories/order_repository.dart';
import 'package:dartz/dartz.dart';

class DeleteOrder {
  final OrderRepository repository;

  DeleteOrder(this.repository);

  Future<Either<Failure, void>> call(String orderId) {
    return repository.deleteOrder(orderId);
  }
}
