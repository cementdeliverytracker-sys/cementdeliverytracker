import 'package:tep/core/errors/failures.dart';
import 'package:tep/features/orders/domain/repositories/order_repository.dart';
import 'package:dartz/dartz.dart';

class DeleteOrder {
  final OrderRepository repository;

  DeleteOrder(this.repository);

  Future<Either<Failure, void>> call(String orderId) {
    return repository.deleteOrder(orderId);
  }
}
