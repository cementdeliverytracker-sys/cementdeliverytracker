import 'package:cementdeliverytracker/core/constants/app_constants.dart';
import 'package:cementdeliverytracker/core/utils/app_utils.dart';
import 'package:cementdeliverytracker/features/auth/presentation/providers/auth_notifier.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:cementdeliverytracker/features/orders/domain/entities/order.dart';
import 'package:cementdeliverytracker/features/orders/presentation/providers/orders_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class CreateOrderPage extends StatefulWidget {
  const CreateOrderPage({super.key});

  @override
  State<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends State<CreateOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameCtrl = TextEditingController();
  final _customerPhoneCtrl = TextEditingController();
  final _deliveryAddressCtrl = TextEditingController();
  final _cementTypeCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _pricePerBagCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _customerPhoneCtrl.dispose();
    _deliveryAddressCtrl.dispose();
    _cementTypeCtrl.dispose();
    _quantityCtrl.dispose();
    _pricePerBagCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _totalAmount {
    final quantity = int.tryParse(_quantityCtrl.text) ?? 0;
    final pricePerBag = double.tryParse(_pricePerBagCtrl.text) ?? 0.0;
    return quantity * pricePerBag;
  }

  Future<void> _saveOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final user = context.read<AuthNotifier>().user;
    final userData = context.read<DashboardProvider>().userData;
    if (user == null || userData == null) {
      AppUtils.showSnackBar(context, 'User not found');
      setState(() => _saving = false);
      return;
    }

    final adminId = (userData.adminId ?? '').trim().isEmpty
        ? user.id
        : (userData.adminId ?? '').trim();

    if (adminId.isEmpty) {
      AppUtils.showSnackBar(
        context,
        'Admin ID not found. Please contact support.',
      );
      setState(() => _saving = false);
      return;
    }

    final order = Order(
      id: '', // Will be set by Firestore
      adminId: adminId,
      createdBy: user.id,
      customerName: _customerNameCtrl.text.trim(),
      customerPhone: _customerPhoneCtrl.text.trim(),
      deliveryAddress: _deliveryAddressCtrl.text.trim(),
      cementType: _cementTypeCtrl.text.trim(),
      quantity: int.parse(_quantityCtrl.text),
      pricePerBag: double.parse(_pricePerBagCtrl.text),
      totalAmount: _totalAmount,
      status: OrderStatus.pending,
      createdAt: DateTime.now(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    final success = await context.read<OrdersProvider>().createOrder(order);

    setState(() => _saving = false);

    if (mounted) {
      if (success) {
        AppUtils.showSnackBar(context, 'Order created successfully');
        Navigator.pop(context);
      } else {
        final error = context.read<OrdersProvider>().errorMessage;
        AppUtils.showSnackBar(context, 'Failed to create order: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Order')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Customer Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _customerNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Customer Name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => v?.trim().isEmpty ?? true
                    ? 'Customer name is required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _customerPhoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) => v?.trim().isEmpty ?? true
                    ? 'Phone number is required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _deliveryAddressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Delivery Address',
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
                validator: (v) => v?.trim().isEmpty ?? true
                    ? 'Delivery address is required'
                    : null,
              ),
              const SizedBox(height: 24),
              const Text(
                'Order Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cementTypeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Cement Type',
                  hintText: 'e.g., OPC 53 Grade',
                  prefixIcon: Icon(Icons.build),
                ),
                validator: (v) => v?.trim().isEmpty ?? true
                    ? 'Cement type is required'
                    : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Quantity (bags)',
                        prefixIcon: Icon(Icons.shopping_bag),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        if (v?.trim().isEmpty ?? true) {
                          return 'Quantity is required';
                        }
                        final qty = int.tryParse(v!);
                        if (qty == null || qty <= 0) {
                          return 'Enter valid quantity';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _pricePerBagCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Price per bag',
                        prefixIcon: Icon(Icons.currency_rupee),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        if (v?.trim().isEmpty ?? true) {
                          return 'Price is required';
                        }
                        final price = double.tryParse(v!);
                        if (price == null || price <= 0) {
                          return 'Enter valid price';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6F00).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFFF6F00).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '₹${_totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFF6F00),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Any additional information',
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _saveOrder,
                  icon: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle),
                  label: Text(_saving ? 'Creating...' : 'Create Order'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6F00),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
