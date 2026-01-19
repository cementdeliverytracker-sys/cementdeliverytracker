import 'dart:io';

import 'package:cementdeliverytracker/core/constants/app_constants.dart';
import 'package:cementdeliverytracker/features/auth/presentation/providers/auth_notifier.dart';
import 'package:cementdeliverytracker/shared/widgets/settings_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;

  late final List<Widget> _screens = [
    const DashboardScreen(),
    const OrdersScreen(),
    const EmployeesScreen(),
    const ReportsScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 600;

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF2C2C2C),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF6F00),
          secondary: Color(0xFFFF6F00),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          actions: _selectedIndex == 4
              ? null
              : [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications),
                  ),
                ],
        ),
        body: IndexedStack(index: _selectedIndex, children: _screens),
        bottomNavigationBar: isLargeScreen
            ? null
            : BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                selectedItemColor: const Color(0xFFFF6F00),
                unselectedItemColor: Colors.white70,
                backgroundColor: const Color(0xFF2C2C2C),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard),
                    label: 'Dashboard',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.list),
                    label: 'Orders',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.people),
                    label: 'Employees',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.report),
                    label: 'Reports',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.settings),
                    label: 'Settings',
                  ),
                ],
              ),
        drawer: isLargeScreen
            ? Drawer(
                child: ListView(
                  children: [
                    const DrawerHeader(
                      child: Text(
                        'Admin Dashboard',
                        style: TextStyle(color: Colors.white, fontSize: 24),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.dashboard, color: Colors.white),
                      title: const Text('Dashboard'),
                      onTap: () {
                        _onItemTapped(0);
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.list, color: Colors.white),
                      title: const Text('Orders'),
                      onTap: () {
                        _onItemTapped(1);
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.people, color: Colors.white),
                      title: const Text('Employees'),
                      onTap: () {
                        _onItemTapped(2);
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.report, color: Colors.white),
                      title: const Text('Reports'),
                      onTap: () {
                        _onItemTapped(3);
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.settings, color: Colors.white),
                      title: const Text('Settings'),
                      onTap: () {
                        _onItemTapped(4);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }
}

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

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
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
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
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
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 64,
                            height: 64,
                            child: logoUrl != null && logoUrl.isNotEmpty
                                ? Image.network(logoUrl, fit: BoxFit.cover)
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
                                  color: Color.fromARGB(255, 241, 241, 238),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(0, 2),
                                      blurRadius: 4,
                                      color: Color(0x40000000),
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
              ),
            ),
          );
        }

        // No enterprise yet — show setup form
        return SingleChildScrollView(
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
                          style: const TextStyle(
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
                          value: _selectedCategory,
                          items: _categories
                              .map(
                                (c) =>
                                    DropdownMenuItem(value: c, child: Text(c)),
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
    );
  }
}

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Orders Screen',
        style: TextStyle(fontSize: 24, color: Colors.white),
      ),
    );
  }
}

class EmployeesScreen extends StatelessWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Employees Screen',
        style: TextStyle(fontSize: 24, color: Colors.white),
      ),
    );
  }
}

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Reports Screen',
        style: TextStyle(fontSize: 24, color: Colors.white),
      ),
    );
  }
}
