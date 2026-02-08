import 'package:cementdeliverytracker/core/theme/app_colors.dart';
import 'package:cementdeliverytracker/features/auth/presentation/providers/auth_notifier.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/pages/admin/services/admin_distributor_service.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/pages/admin/widgets/location_picker_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EmployeeAddDistributorDialog extends StatefulWidget {
  final String adminId;

  const EmployeeAddDistributorDialog({required this.adminId, super.key});

  @override
  State<EmployeeAddDistributorDialog> createState() =>
      _EmployeeAddDistributorDialogState();
}

class _EmployeeAddDistributorDialogState
    extends State<EmployeeAddDistributorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _service = AdminDistributorService();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _regionCtrl;

  double? _selectedLatitude;
  double? _selectedLongitude;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _locationCtrl = TextEditingController();
    _regionCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _locationCtrl.dispose();
    _regionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final picked = await Navigator.push<LocationPickerResult>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerWidget(
          onLocationSelected: (location) {
            // Will be called before pop
          },
        ),
      ),
    );

    if (picked != null) {
      setState(() {
        _locationCtrl.text = picked.address;
        _selectedLatitude = picked.latitude;
        _selectedLongitude = picked.longitude;
      });
    }
  }

  Future<void> _saveDistributor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = context.read<AuthNotifier>().user;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not authenticated')),
          );
        }
        return;
      }

      await _service.addDistributor(
        adminId: widget.adminId,
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        region: _regionCtrl.text.trim(),
        latitude: _selectedLatitude,
        longitude: _selectedLongitude,
        createdByUserId: user.id,
        createdByName: user.displayName ?? user.email,
        createdByType: 'employee',
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Distributor added successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Add Distributor',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'All fields are required',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  // Name Field
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Distributor Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Phone Field
                  TextFormField(
                    controller: _phoneCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Phone is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Email Field
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!value.contains('@')) {
                        return 'Invalid email format';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Location Field with Map Picker
                  TextFormField(
                    controller: _locationCtrl,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Location Address',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.location_on),
                      suffixIcon: IconButton(
                        onPressed: _isLoading ? null : _pickLocation,
                        icon: const Icon(Icons.map),
                        tooltip: 'Pick location on map',
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Location is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Region Field
                  TextFormField(
                    controller: _regionCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Assigned Region',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_city),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Region is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Location confirmation text
                  if (_selectedLatitude != null && _selectedLongitude != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Location: ${_selectedLatitude!.toStringAsFixed(4)}, ${_selectedLongitude!.toStringAsFixed(4)}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _saveDistributor,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Add Distributor'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
