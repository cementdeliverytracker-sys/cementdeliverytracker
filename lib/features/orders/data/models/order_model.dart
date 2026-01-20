import 'package:cementdeliverytracker/features/orders/domain/entities/order.dart';

class OrderModel extends Order {
  const OrderModel({
    required super.id,
    required super.adminId,
    required super.createdBy,
    required super.customerName,
    required super.customerPhone,
    required super.deliveryAddress,
    required super.cementType,
    required super.quantity,
    required super.pricePerBag,
    required super.totalAmount,
    required super.status,
    required super.createdAt,
    super.updatedAt,
    super.deliveredAt,
    super.assignedDriverId,
    super.assignedDriverName,
    super.notes,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json, String id) {
    return OrderModel(
      id: id,
      adminId: json['adminId'] as String,
      createdBy: json['createdBy'] as String,
      customerName: json['customerName'] as String,
      customerPhone: json['customerPhone'] as String,
      deliveryAddress: json['deliveryAddress'] as String,
      cementType: json['cementType'] as String,
      quantity: json['quantity'] as int,
      pricePerBag: (json['pricePerBag'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      status: OrderStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'] as String)
          : null,
      assignedDriverId: json['assignedDriverId'] as String?,
      assignedDriverName: json['assignedDriverName'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'adminId': adminId,
      'createdBy': createdBy,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'deliveryAddress': deliveryAddress,
      'cementType': cementType,
      'quantity': quantity,
      'pricePerBag': pricePerBag,
      'totalAmount': totalAmount,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'assignedDriverId': assignedDriverId,
      'assignedDriverName': assignedDriverName,
      'notes': notes,
    };
  }

  factory OrderModel.fromEntity(Order order) {
    return OrderModel(
      id: order.id,
      adminId: order.adminId,
      createdBy: order.createdBy,
      customerName: order.customerName,
      customerPhone: order.customerPhone,
      deliveryAddress: order.deliveryAddress,
      cementType: order.cementType,
      quantity: order.quantity,
      pricePerBag: order.pricePerBag,
      totalAmount: order.totalAmount,
      status: order.status,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
      deliveredAt: order.deliveredAt,
      assignedDriverId: order.assignedDriverId,
      assignedDriverName: order.assignedDriverName,
      notes: order.notes,
    );
  }
}
