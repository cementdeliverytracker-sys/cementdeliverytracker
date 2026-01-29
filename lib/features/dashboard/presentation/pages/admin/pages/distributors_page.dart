import 'package:cementdeliverytracker/core/constants/app_constants.dart';
import 'package:cementdeliverytracker/core/theme/app_colors.dart';
import 'package:cementdeliverytracker/features/auth/presentation/providers/auth_notifier.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/pages/admin/services/admin_distributor_service.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/pages/admin/widgets/location_picker_widget.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DistributorsScreen extends StatefulWidget {
  const DistributorsScreen({super.key});

  @override
  State<DistributorsScreen> createState() => _DistributorsScreenState();
}

class _DistributorsScreenState extends State<DistributorsScreen> {
  final _service = AdminDistributorService();

  @override
  Widget build(BuildContext context) {
    final adminId = context.read<AuthNotifier>().user?.id;
    if (adminId == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(title: const Text('Distributors')),
        body: Center(
          child: Text(
            'No admin user found',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Distributors')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openDistributorForm(context, adminId),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Add Distributor'),
      ),
      body: Padding(
        padding: const EdgeInsets.only(
          left: AppConstants.defaultPadding,
          right: AppConstants.defaultPadding,
          top: AppConstants.defaultPadding,
          bottom: 90,
        ),
        child: ListView(
          children: [
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _service.getDistributorsStream(adminId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return DashboardCard(
                    onTap: null,
                    child: Row(
                      children: const [
                        SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Loading distributors...'),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return DashboardCard(
                    onTap: null,
                    child: Text(
                      'Failed to load distributors: ${snapshot.error}',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                final distributorCount = docs.length;

                return Column(
                  children: [
                    DashboardCard(
                      child: Row(
                        children: [
                          Container(
                            height: 48,
                            width: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.storefront,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Distributors',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$distributorCount distributor${distributorCount != 1 ? 's' : ''}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (docs.isEmpty)
                      const EmptyState(
                        message: 'No distributors yet',
                        icon: Icons.storefront_outlined,
                      )
                    else
                      ...docs.asMap().entries.map((entry) {
                        final index = entry.key;
                        final doc = entry.value;
                        final data = doc.data();
                        return Column(
                          children: [
                            DashboardCard(
                              child: ListTile(
                                leading: const Icon(
                                  Icons.storefront,
                                  color: AppColors.primary,
                                ),
                                title: Text(
                                  data['name'] ?? 'No name',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                subtitle: Text(
                                  (data['region'] ?? 'No region') as String,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                trailing: Icon(
                                  Icons.chevron_right,
                                  color: Theme.of(context).iconTheme.color,
                                ),
                                onTap: () => _openDistributorDetail(
                                  context,
                                  adminId,
                                  doc.id,
                                  data,
                                ),
                              ),
                            ),
                            if (index < docs.length - 1)
                              const SizedBox(height: 8),
                          ],
                        );
                      }),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openDistributorForm(
    BuildContext context,
    String adminId, {
    String? docId,
    Map<String, dynamic>? existing,
  }) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: existing?['name']);
    final phoneCtrl = TextEditingController(text: existing?['phone']);
    final emailCtrl = TextEditingController(text: existing?['email']);
    final locationCtrl = TextEditingController(text: existing?['location']);
    final regionCtrl = TextEditingController(text: existing?['region']);
    double? selectedLatitude = existing?['latitude'];
    double? selectedLongitude = existing?['longitude'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                docId == null ? 'Add Distributor' : 'Edit Distributor',
                style: Theme.of(
                  ctx,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: nameCtrl,
                style: Theme.of(ctx).textTheme.bodyMedium,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneCtrl,
                style: Theme.of(ctx).textTheme.bodyMedium,
                decoration: const InputDecoration(
                  labelText: 'Phone number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailCtrl,
                style: Theme.of(ctx).textTheme.bodyMedium,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: locationCtrl,
                style: Theme.of(ctx).textTheme.bodyMedium,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  LocationPickerResult? result =
                      selectedLatitude != null && selectedLongitude != null
                      ? LocationPickerResult(
                          latitude: selectedLatitude!,
                          longitude: selectedLongitude!,
                          address: locationCtrl.text,
                        )
                      : null;
                  final picked = await Navigator.push<LocationPickerResult>(
                    ctx,
                    MaterialPageRoute(
                      builder: (context) => LocationPickerWidget(
                        initialLocation: result,
                        onLocationSelected: (location) {
                          // Will be called before pop
                        },
                      ),
                    ),
                  );
                  if (picked != null) {
                    locationCtrl.text = picked.address;
                    selectedLatitude = picked.latitude;
                    selectedLongitude = picked.longitude;
                  }
                },
                icon: const Icon(Icons.location_on),
                label: const Text('Pick Location on Map'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: regionCtrl,
                style: Theme.of(ctx).textTheme.bodyMedium,
                decoration: const InputDecoration(
                  labelText: 'Assigned region',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      if (docId == null) {
                        await _service.addDistributor(
                          adminId: adminId,
                          name: nameCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          location: locationCtrl.text.trim(),
                          region: regionCtrl.text.trim(),
                          latitude: selectedLatitude,
                          longitude: selectedLongitude,
                        );
                      } else {
                        await _service.updateDistributor(
                          distributorId: docId,
                          name: nameCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          location: locationCtrl.text.trim(),
                          region: regionCtrl.text.trim(),
                          latitude: selectedLatitude,
                          longitude: selectedLongitude,
                        );
                      }
                      if (mounted) Navigator.pop(ctx);
                    },
                    child: Text(docId == null ? 'Save' : 'Update'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDistributorDetail(
    BuildContext context,
    String adminId,
    String distributorId,
    Map<String, dynamic> data,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['name'] ?? 'Distributor',
              style: Theme.of(
                ctx,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _infoRow('Phone', data['phone']),
            _infoRow('Email', data['email']),
            _infoRow('Location', data['location']),
            _infoRow('Region', data['region']),
            _infoRow('Created', _formatDate(data['createdAt'])),
            if (data['latitude'] != null && data['longitude'] != null) ...[
              _infoRow(
                'Coordinates',
                '${(data['latitude'] as num?)?.toStringAsFixed(6)}, ${(data['longitude'] as num?)?.toStringAsFixed(6)}',
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  final latitude = data['latitude'] as num?;
                  final longitude = data['longitude'] as num?;
                  if (latitude != null && longitude != null) {
                    Navigator.push<LocationPickerResult>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LocationPickerWidget(
                          initialLocation: LocationPickerResult(
                            latitude: latitude.toDouble(),
                            longitude: longitude.toDouble(),
                            address: data['location'] ?? 'Location',
                          ),
                          onLocationSelected: (_) {},
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.map),
                label: const Text('View on Map'),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _openDistributorForm(
                    context,
                    adminId,
                    docId: distributorId,
                    existing: data,
                  ),
                  child: const Text('Edit'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () async {
                    await _service.deleteDistributor(distributorId);
                    if (Navigator.canPop(ctx)) Navigator.pop(ctx);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                  ),
                  child: const Text('Remove'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          Flexible(
            child: Text(
              (value ?? 'N/A').toString(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic ts) {
    if (ts is Timestamp) {
      final dt = ts.toDate();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    }
    return 'N/A';
  }
}
