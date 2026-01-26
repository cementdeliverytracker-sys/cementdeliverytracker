import 'dart:io';
import 'dart:math';

import 'package:cementdeliverytracker/core/constants/app_constants.dart';
import 'package:cementdeliverytracker/features/auth/presentation/providers/auth_notifier.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/pages/admin/pages/distributors_page.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/pages/admin/pages/employees_tab_page.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/pages/admin/services/admin_distributor_service.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/pages/admin/services/admin_employee_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _enterpriseNameCtrl = TextEditingController();
  String? _selectedCategory;
  XFile? _pickedLogo;
  bool _saving = false;
  int _refreshNonce = 0;
  final List<String> _categories = const [
    'Construction',
    'Logistics',
    'Manufacturing',
    'Retail',
    'Services',
    'Other',
  ];

  @override
  void dispose() {
    _enterpriseNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _pickedLogo = image);
    }
  }

  String _generateAdminCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> _saveEnterprise(String userId) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      String? logoUrl;
      if (_pickedLogo != null) {
        final fileExt = _pickedLogo!.name.split('.').last;
        final ref = FirebaseStorage.instance
            .ref()
            .child(AppConstants.enterpriseLogosPath)
            .child(
              '${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt',
            );
        await ref.putData(await _pickedLogo!.readAsBytes());
        logoUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance
          .collection(AppConstants.enterprisesCollection)
          .doc(userId)
          .set({
            'ownerId': userId,
            'name': _enterpriseNameCtrl.text.trim(),
            'category': _selectedCategory,
            'logoUrl': logoUrl,
            'adminCode': _generateAdminCode(),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enterprise saved successfully')),
        );
        setState(() {}); // refresh FutureBuilder
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthNotifier>().user?.id;

    if (userId == null) {
      return const Center(
        child: Text('No user found', style: TextStyle(color: Colors.white70)),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _handleRefresh(userId),
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.enterprisesCollection)
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final exists = snapshot.data?.exists == true;
          final data = snapshot.data?.data();

          if (exists && data != null) {
            final name = (data['name'] ?? '') as String;
            final category = (data['category'] ?? '') as String;
            final logoUrl = data['logoUrl'] as String?;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    children: [
                      Card(
                        color: const Color(0xFF1E1E1E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.defaultBorderRadius,
                          ),
                        ),
                        elevation: AppConstants.defaultElevation,
                        child: Padding(
                          padding: const EdgeInsets.all(
                            AppConstants.defaultPadding,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  width: 64,
                                  height: 64,
                                  child: logoUrl != null && logoUrl.isNotEmpty
                                      ? Image.network(
                                          logoUrl,
                                          fit: BoxFit.cover,
                                        )
                                      : const DecoratedBox(
                                          decoration: BoxDecoration(
                                            color: Colors.white10,
                                          ),
                                          child: Icon(
                                            Icons.business,
                                            color: Colors.white54,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (name.isEmpty ? 'Enterprise' : name)
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        color: Color.fromARGB(
                                          255,
                                          241,
                                          241,
                                          238,
                                        ),
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 2.0,
                                        height: 1.2,
                                        shadows: [
                                          Shadow(
                                            offset: Offset(2, 2),
                                            blurRadius: 4,
                                            color: Color(0x88000000),
                                          ),
                                          Shadow(
                                            offset: Offset(4, 4),
                                            blurRadius: 8,
                                            color: Color(0x55000000),
                                          ),
                                          Shadow(
                                            offset: Offset(-1, -1),
                                            blurRadius: 2,
                                            color: Color(0x44FFFFFF),
                                          ),
                                          Shadow(
                                            offset: Offset(6, 6),
                                            blurRadius: 12,
                                            color: Color(0xAAFF6F00),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (category.isNotEmpty)
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.category_outlined,
                                            size: 16,
                                            color: Color(0xFFFF6F00),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            category,
                                            style: const TextStyle(
                                              color: Color(0xFFFF6F00),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildEmployeeInfoCard(context, userId),
                      const SizedBox(height: 16),
                      _buildDealerInfoCard(context, userId),
                      const SizedBox(height: 16),
                      _buildPendingOrdersCard(context, userId),
                    ],
                  ),
                ),
              ),
            );
          }

          // No enterprise yet — show setup form
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  color: const Color(0xFF1E1E1E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.defaultBorderRadius,
                    ),
                  ),
                  elevation: AppConstants.defaultElevation,
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Set up your enterprise',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _enterpriseNameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Enterprise name',
                              hintText: 'e.g., Alpha Constructions Pvt. Ltd.',
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Enterprise name is required';
                              }
                              if (v.trim().length < 3) {
                                return 'Name must be at least 3 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Category',
                            ),
                            initialValue: _selectedCategory,
                            items: _categories
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedCategory = v),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Please select a category'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.white10,
                                backgroundImage: _pickedLogo != null
                                    ? FileImage(File(_pickedLogo!.path))
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              TextButton.icon(
                                onPressed: _pickLogo,
                                icon: const Icon(Icons.image_outlined),
                                label: const Text('Add logo (optional)'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _saving
                                  ? null
                                  : () => _saveEnterprise(userId),
                              icon: _saving
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.check_circle_outline),
                              label: Text(
                                _saving ? 'Saving...' : 'Save and continue',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleRefresh(String userId) async {
    // Trigger a manual refresh; Firestore streams are real-time, but this supports pull-to-refresh UX.
    setState(() => _refreshNonce++);
    await FirebaseFirestore.instance
        .collection(AppConstants.enterprisesCollection)
        .doc(userId)
        .get();
  }

  Widget _buildEmployeeInfoCard(BuildContext context, String userId) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: AdminEmployeeService().getEmployeesStream(userId),
      builder: (context, snapshot) {
        final totalEmployees = snapshot.data?.docs.length ?? 0;

        // Count logged-in employees based on status field
        int loggedInToday = 0;
        if (snapshot.data != null) {
          for (var doc in snapshot.data!.docs) {
            final status = (doc.data()['status'] ?? 'logged_out') as String;
            if (status == 'logged_in') {
              loggedInToday++;
            }
          }
        }
        final notLoggedInToday = totalEmployees - loggedInToday;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EmployeesListFullPage(adminId: userId),
              ),
            );
          },
          child: Card(
            color: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppConstants.defaultBorderRadius,
              ),
            ),
            elevation: AppConstants.defaultElevation,
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: const Color(0x33FF6F00),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.people,
                          color: Color(0xFFFF6F00),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Employee Info',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Total: $totalEmployees employees',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox.shrink(),
                      // Green dot - Logged in today
                      // Green dot - Logged in today
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$loggedInToday',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 24),
                          // Red dot - Not logged in today
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$notLoggedInToday',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDealerInfoCard(BuildContext context, String userId) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: AdminDistributorService().getDistributorsStream(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // Debug: Show error if there's an issue
          return Card(
            color: const Color(0xFF1E1E1E),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        final totalDealers = snapshot.data?.docs.length ?? 0;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DistributorsScreen()),
            );
          },
          child: Card(
            color: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppConstants.defaultBorderRadius,
              ),
            ),
            elevation: AppConstants.defaultElevation,
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: const Color(0x33FF6F00),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.local_shipping,
                          color: Color(0xFFFF6F00),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dealer Info',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Total: $totalDealers dealers',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x33FF6F00),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: Color(0xFFFF6F00),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$totalDealers Active',
                              style: const TextStyle(
                                color: Color(0xFFFF6F00),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPendingOrdersCard(BuildContext context, String userId) {
    // TODO: Replace with actual pending orders stream from service
    const totalPendingOrders = 0;

    return GestureDetector(
      onTap: () {
        // TODO: Navigate to Pending Orders screen when implemented
      },
      child: Card(
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        elevation: AppConstants.defaultElevation,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: const Color(0x33FF6F00),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.shopping_cart,
                      color: Color(0xFFFF6F00),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pending Orders',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total: $totalPendingOrders orders',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x33FF6F00),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.pending_actions,
                          size: 16,
                          color: Color(0xFFFF6F00),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$totalPendingOrders Pending',
                          style: const TextStyle(
                            color: Color(0xFFFF6F00),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
