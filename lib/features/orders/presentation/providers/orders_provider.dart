import 'package:cementdeliverytracker/features/orders/domain/entities/order.dart';
import 'package:cementdeliverytracker/features/orders/domain/usecases/create_order.dart';
import 'package:cementdeliverytracker/features/orders/domain/usecases/delete_order.dart';
import 'package:cementdeliverytracker/features/orders/domain/usecases/get_orders.dart';
import 'package:cementdeliverytracker/features/orders/domain/usecases/update_order.dart';
import 'package:flutter/material.dart';

enum OrdersState { initial, loading, loaded, error }

class OrdersProvider extends ChangeNotifier {
  final GetOrders getOrdersUseCase;
  final CreateOrder createOrderUseCase;
  final UpdateOrder updateOrderUseCase;
  final DeleteOrder deleteOrderUseCase;

  OrdersProvider({
    required this.getOrdersUseCase,
    required this.createOrderUseCase,
    required this.updateOrderUseCase,
    required this.deleteOrderUseCase,
  });

  OrdersState _state = OrdersState.initial;
  List<Order> _orders = [];
  String? _errorMessage;

  OrdersState get state => _state;
  List<Order> get orders => _orders;
  String? get errorMessage => _errorMessage;

  Future<void> loadOrders(String adminId) async {
    _state = OrdersState.loading;
    notifyListeners();

    final result = await getOrdersUseCase(adminId);

    result.fold(
      (failure) {
        _state = OrdersState.error;
        _errorMessage = failure.message;
        notifyListeners();
      },
      (orders) {
        _state = OrdersState.loaded;
        _orders = orders.cast<Order>();
        _errorMessage = null;
        notifyListeners();
      },
    );
  }

  Future<bool> createOrder(Order order) async {
    final result = await createOrderUseCase(order);

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        return false;
      },
      (orderId) {
        // Reload orders after creation
        loadOrders(order.adminId);
        return true;
      },
    );
  }

  Future<bool> updateOrder(Order order) async {
    final result = await updateOrderUseCase(order);

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        return false;
      },
      (_) {
        // Reload orders after update
        loadOrders(order.adminId);
        return true;
      },
    );
  }

  Future<bool> deleteOrder(String orderId, String adminId) async {
    final result = await deleteOrderUseCase(orderId);

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        return false;
      },
      (_) {
        // Reload orders after deletion
        loadOrders(adminId);
        return true;
      },
    );
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
