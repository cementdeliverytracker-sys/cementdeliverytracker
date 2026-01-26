import 'package:cementdeliverytracker/core/constants/app_constants.dart';
import 'package:cementdeliverytracker/features/auth/presentation/providers/auth_notifier.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/pages/admin/services/admin_distributor_service.dart';
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
      return const Scaffold(
        backgroundColor: Color(0xFF2C2C2C),
        body: Center(
          child: Text(
            'No admin user found',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF2C2C2C),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Distributors',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                  onPressed: () => _openDistributorForm(context, adminId),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _service.getDistributorsStream(adminId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingState();
                  }
                  if (snapshot.hasError) {
                    return ErrorState(
                      message: 'Failed to load distributors: ${snapshot.error}',
                    );
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const EmptyState(
                      message: 'No distributors yet',
                      icon: Icons.storefront_outlined,
                    );
                  }
                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data();
                      return DashboardCard(
                        child: ListTile(
                          leading: const Icon(
                            Icons.storefront,
                            color: Colors.white,
                          ),
                          title: Text(
                            data['name'] ?? 'No name',
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            (data['region'] ?? 'No region') as String,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: Colors.white70,
                          ),
                          onTap: () => _openDistributorDetail(
                            context,
                            adminId,
                            doc.id,
                            data,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name required' : null,
              ),
              TextFormField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone number'),
                keyboardType: TextInputType.phone,
              ),
              TextFormField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextFormField(
                controller: locationCtrl,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              TextFormField(
                controller: regionCtrl,
                decoration: const InputDecoration(labelText: 'Assigned region'),
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
                        );
                      } else {
                        await _service.updateDistributor(
                          distributorId: docId,
                          name: nameCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          location: locationCtrl.text.trim(),
                          region: regionCtrl.text.trim(),
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
      backgroundColor: const Color(0xFF1E1E1E),
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _infoRow('Phone', data['phone']),
            _infoRow('Email', data['email']),
            _infoRow('Location', data['location']),
            _infoRow('Region', data['region']),
            _infoRow('Created', _formatDate(data['createdAt'])),
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
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          Flexible(
            child: Text(
              (value ?? 'N/A').toString(),
              style: const TextStyle(color: Colors.white),
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
