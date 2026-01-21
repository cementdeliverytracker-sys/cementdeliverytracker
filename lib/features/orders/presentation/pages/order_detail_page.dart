import 'package:cementdeliverytracker/core/constants/app_constants.dart';
import 'package:cementdeliverytracker/core/utils/app_utils.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:cementdeliverytracker/features/orders/domain/entities/order.dart';
import 'package:cementdeliverytracker/features/orders/presentation/providers/orders_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class OrderDetailPage extends StatelessWidget {
  final Order order;

  const OrderDetailPage({super.key, required this.order});

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.inTransit:
        return Colors.purple;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  Future<void> _updateStatus(
    BuildContext context,
    OrderStatus newStatus,
  ) async {
    final updatedOrder = order.copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
      deliveredAt: newStatus == OrderStatus.delivered
          ? DateTime.now()
          : order.deliveredAt,
    );

    final success = await context.read<OrdersProvider>().updateOrder(
      updatedOrder,
    );

    if (context.mounted) {
      if (success) {
        AppUtils.showSnackBar(context, 'Status updated successfully');
        Navigator.pop(context);
      } else {
        final error = context.read<OrdersProvider>().errorMessage;
        AppUtils.showSnackBar(context, 'Failed to update: $error');
      }
    }
  }

  Future<void> _deleteOrder(BuildContext context) async {
    final userData = context.read<DashboardProvider>().userData;
    final isAdmin = userData?.userType == AppConstants.userTypeAdmin;

    if (!isAdmin) {
      AppUtils.showSnackBar(context, 'Only admins can delete orders');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Order'),
        content: const Text(
          'Are you sure you want to delete this order? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final adminId = (userData?.adminId ?? '').trim().isEmpty
          ? userData?.userId ?? ''
          : (userData?.adminId ?? '').trim();
      final success = await context.read<OrdersProvider>().deleteOrder(
        order.id,
        adminId,
      );

      if (context.mounted) {
        if (success) {
          AppUtils.showSnackBar(context, 'Order deleted successfully');
          Navigator.pop(context);
        } else {
          final error = context.read<OrdersProvider>().errorMessage;
          AppUtils.showSnackBar(context, 'Failed to delete: $error');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userData = context.read<DashboardProvider>().userData;
    final isAdmin = userData?.userType == AppConstants.userTypeAdmin;
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        actions: [
          if (isAdmin && order.status != OrderStatus.cancelled)
            PopupMenuButton<OrderStatus>(
              icon: const Icon(Icons.more_vert),
              onSelected: (status) => _updateStatus(context, status),
              itemBuilder: (context) => [
                if (order.status != OrderStatus.confirmed)
                  const PopupMenuItem(
                    value: OrderStatus.confirmed,
                    child: Text('Mark as Confirmed'),
                  ),
                if (order.status != OrderStatus.inTransit)
                  const PopupMenuItem(
                    value: OrderStatus.inTransit,
                    child: Text('Mark as In Transit'),
                  ),
                if (order.status != OrderStatus.delivered)
                  const PopupMenuItem(
                    value: OrderStatus.delivered,
                    child: Text('Mark as Delivered'),
                  ),
                if (order.status != OrderStatus.cancelled)
                  const PopupMenuItem(
                    value: OrderStatus.cancelled,
                    child: Text('Cancel Order'),
                  ),
              ],
            ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteOrder(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getStatusColor(order.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getStatusColor(order.status),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.circle,
                    size: 12,
                    color: _getStatusColor(order.status),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    order.status.displayName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _getStatusColor(order.status),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _SectionHeader(title: 'Customer Information'),
            const SizedBox(height: 12),
            _InfoTile(
              icon: Icons.person,
              label: 'Name',
              value: order.customerName,
            ),
            _InfoTile(
              icon: Icons.phone,
              label: 'Phone',
              value: order.customerPhone,
            ),
            _InfoTile(
              icon: Icons.location_on,
              label: 'Delivery Address',
              value: order.deliveryAddress,
            ),
            const SizedBox(height: 24),
            _SectionHeader(title: 'Order Details'),
            const SizedBox(height: 12),
            _InfoTile(
              icon: Icons.build,
              label: 'Cement Type',
              value: order.cementType,
            ),
            _InfoTile(
              icon: Icons.shopping_bag,
              label: 'Quantity',
              value: '${order.quantity} bags',
            ),
            _InfoTile(
              icon: Icons.currency_rupee,
              label: 'Price per Bag',
              value: '₹${order.pricePerBag.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6F00).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFF6F00), width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '₹${order.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFF6F00),
                    ),
                  ),
                ],
              ),
            ),
            if (order.notes != null && order.notes!.isNotEmpty) ...[
              const SizedBox(height: 24),
              _SectionHeader(title: 'Notes'),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  order.notes!,
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ),
            ],
            const SizedBox(height: 24),
            _SectionHeader(title: 'Timeline'),
            const SizedBox(height: 12),
            _InfoTile(
              icon: Icons.schedule,
              label: 'Created At',
              value: dateFormat.format(order.createdAt),
            ),
            if (order.updatedAt != null)
              _InfoTile(
                icon: Icons.update,
                label: 'Last Updated',
                value: dateFormat.format(order.updatedAt!),
              ),
            if (order.deliveredAt != null)
              _InfoTile(
                icon: Icons.check_circle,
                label: 'Delivered At',
                value: dateFormat.format(order.deliveredAt!),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFFFF6F00)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
