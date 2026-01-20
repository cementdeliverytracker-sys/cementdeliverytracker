import 'package:equatable/equatable.dart';

class Order extends Equatable {
  final String id;
  final String adminId;
  final String createdBy;
  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
  final String cementType;
  final int quantity; // in bags
  final double pricePerBag;
  final double totalAmount;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deliveredAt;
  final String? assignedDriverId;
  final String? assignedDriverName;
  final String? notes;

  const Order({
    required this.id,
    required this.adminId,
    required this.createdBy,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.cementType,
    required this.quantity,
    required this.pricePerBag,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.deliveredAt,
    this.assignedDriverId,
    this.assignedDriverName,
    this.notes,
  });

  @override
  List<Object?> get props => [
    id,
    adminId,
    createdBy,
    customerName,
    customerPhone,
    deliveryAddress,
    cementType,
    quantity,
    pricePerBag,
    totalAmount,
    status,
    createdAt,
    updatedAt,
    deliveredAt,
    assignedDriverId,
    assignedDriverName,
    notes,
  ];

  Order copyWith({
    String? id,
    String? adminId,
    String? createdBy,
    String? customerName,
    String? customerPhone,
    String? deliveryAddress,
    String? cementType,
    int? quantity,
    double? pricePerBag,
    double? totalAmount,
    OrderStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deliveredAt,
    String? assignedDriverId,
    String? assignedDriverName,
    String? notes,
  }) {
    return Order(
      id: id ?? this.id,
      adminId: adminId ?? this.adminId,
      createdBy: createdBy ?? this.createdBy,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      cementType: cementType ?? this.cementType,
      quantity: quantity ?? this.quantity,
      pricePerBag: pricePerBag ?? this.pricePerBag,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      assignedDriverId: assignedDriverId ?? this.assignedDriverId,
      assignedDriverName: assignedDriverName ?? this.assignedDriverName,
      notes: notes ?? this.notes,
    );
  }
}

enum OrderStatus {
  pending,
  confirmed,
  inTransit,
  delivered,
  cancelled;

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.inTransit:
        return 'In Transit';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  static OrderStatus fromString(String status) {
    return OrderStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => OrderStatus.pending,
    );
  }
}
