import 'dart:io';
import 'dart:math';

import 'package:cementdeliverytracker/core/constants/app_constants.dart';
import 'package:cementdeliverytracker/features/auth/presentation/providers/auth_notifier.dart';
import 'package:cementdeliverytracker/features/orders/presentation/pages/orders_list_page.dart';
import 'package:cementdeliverytracker/shared/widgets/settings_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    const OrdersListPage(),
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
                  ],
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

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthNotifier>().user?.id;

    if (userId == null) {
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
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const Text(
                  'Employees',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection(AppConstants.usersCollection)
                      .where(
                        'userType',
                        isEqualTo: AppConstants.userTypeEmployee,
                      )
                      .where('adminId', isEqualTo: userId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildEmployeesCard(
                        onTap: null,
                        child: Row(
                          children: const [
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Loading employees...',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return _buildEmployeesCard(
                        onTap: null,
                        child: Text(
                          'Failed to load employees: ${snapshot.error}',
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      );
                    }

                    final employeeCount = snapshot.data?.docs.length ?? 0;

                    return _buildEmployeesCard(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EmployeesListPage(adminId: userId),
                          ),
                        );
                      },
                      child: Row(
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
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Employees',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$employeeCount approved',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Tap to view list',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
          _buildPendingRequestsButton(userId),
        ],
      ),
    );
  }

  Widget _buildEmployeesCard({required Widget child, VoidCallback? onTap}) {
    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      elevation: AppConstants.defaultElevation,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: child,
        ),
      ),
    );
  }

  Widget _buildPendingRequestsButton(String userId) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 56,
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PendingEmployeeRequestsPage(adminId: userId),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6F00),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: const Icon(Icons.pending_actions, size: 20),
            label: const Text(
              'Pending Requests',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EmployeesListPage extends StatefulWidget {
  final String adminId;

  const EmployeesListPage({required this.adminId, super.key});

  @override
  State<EmployeesListPage> createState() => _EmployeesListPageState();
}

class _EmployeesListPageState extends State<EmployeesListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Employees')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.usersCollection)
            .where('userType', isEqualTo: AppConstants.userTypeEmployee)
            .where('adminId', isEqualTo: widget.adminId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load employees: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          final employees = snapshot.data?.docs ?? [];

          if (employees.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.people_outline, size: 64, color: Colors.white54),
                  SizedBox(height: 12),
                  Text(
                    'No employees yet',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            itemCount: employees.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final doc = employees[index];
              final data = doc.data();
              final name = (data['username'] ?? 'Unnamed') as String;
              final email = (data['email'] ?? 'N/A') as String;
              final phone = (data['phone'] ?? 'N/A') as String;

              return Card(
                color: const Color(0xFF1E1E1E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.defaultBorderRadius,
                  ),
                ),
                elevation: AppConstants.defaultElevation,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFFF6F00),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    '$email • $phone',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.white70,
                  ),
                  onTap: () => _showEmployeeDetails(context, data),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showEmployeeDetails(BuildContext context, Map<String, dynamic> data) {
    final name = (data['username'] ?? 'Unnamed') as String;
    final email = (data['email'] ?? 'N/A') as String;
    final employeeId = (data['employeeId'] ?? 'N/A') as String;
    final age = data['age']?.toString() ?? 'N/A';
    final address = (data['address'] ?? 'N/A') as String;
    final phone = (data['phone'] ?? 'N/A') as String;
    final role = (data['role'] ?? 'Employee') as String;

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
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFFF6F00),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      role,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _detailRow('Employee ID', employeeId),
            _detailRow('Email', email),
            _detailRow('Age', age),
            _detailRow('Phone', phone),
            _detailRow('Address', address),
            _detailRow('Role', role),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class PendingEmployeeRequestsPage extends StatefulWidget {
  final String adminId;

  const PendingEmployeeRequestsPage({required this.adminId, super.key});

  @override
  State<PendingEmployeeRequestsPage> createState() =>
      _PendingEmployeeRequestsPageState();
}

class _PendingEmployeeRequestsPageState
    extends State<PendingEmployeeRequestsPage> {
  @override
  void initState() {
    super.initState();
    // Debug: Print the adminId being queried
    print('DEBUG: Querying for adminId: ${widget.adminId}');
    print(
      'DEBUG: Looking for userType: ${AppConstants.userTypePendingEmployee}',
    );
  }

  Future<void> _showDebugInfo(BuildContext context) async {
    try {
      // Get ALL users with pending_employee userType
      final allPendingEmployees = await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .where('userType', isEqualTo: AppConstants.userTypePendingEmployee)
          .get();

      print(
        'DEBUG: Total pending_employee users: ${allPendingEmployees.docs.length}',
      );

      String debugText = 'All Pending Employees:\n\n';
      for (var doc in allPendingEmployees.docs) {
        final data = doc.data();
        debugText +=
            'User: ${data['username'] ?? 'Unknown'}\n'
            'AdminId: ${data['adminId'] ?? 'NOT SET'}\n'
            'UserType: ${data['userType']}\n'
            'Email: ${data['email'] ?? 'N/A'}\n'
            '---\n';

        print(
          'DEBUG User: ${data['username']}, AdminId: ${data['adminId']}, UserType: ${data['userType']}',
        );
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Debug Info'),
            content: SingleChildScrollView(child: Text(debugText)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('DEBUG ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pending Employee Requests')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.usersCollection)
            .where('userType', isEqualTo: AppConstants.userTypePendingEmployee)
            .where('adminId', isEqualTo: widget.adminId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading requests',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final requests = snapshot.data?.docs ?? [];

          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pending requests',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => _showDebugInfo(context),
                    child: const Text('Show Debug Info'),
                  ),
                ],
              ),
            );
          }

          // Sort requests by requestedAt timestamp (newest first)
          final sortedRequests = List<QueryDocumentSnapshot>.from(requests);
          sortedRequests.sort((a, b) {
            final aTime =
                (a.get('employeeRequestData')?['requestedAt'] as Timestamp?) ??
                Timestamp.now();
            final bTime =
                (b.get('employeeRequestData')?['requestedAt'] as Timestamp?) ??
                Timestamp.now();
            return bTime.compareTo(aTime);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            itemCount: sortedRequests.length,
            itemBuilder: (context, index) {
              final request = sortedRequests[index];
              final data = request.data() as Map<String, dynamic>;
              final username = data['username'] ?? 'Unknown';
              final email = data['email'] ?? 'N/A';
              final requestedAt =
                  (data['employeeRequestData']?['requestedAt'] as Timestamp?)
                      ?.toDate();

              return Card(
                color: const Color(0xFF1E1E1E),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFFFF6F00),
                            radius: 24,
                            child: Text(
                              username[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  username,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  email,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white60,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (requestedAt != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Requested: ${requestedAt.toString().split('.')[0]}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () =>
                                _rejectEmployee(context, request.id),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                            ),
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Reject'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () =>
                                _approveEmployee(context, request.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6F00),
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.check_circle, size: 18),
                            label: const Text('Approve'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _approveEmployee(BuildContext context, String userId) async {
    try {
      // Generate unique 6-digit employee ID
      final employeeId = await _generateUniqueEmployeeId();

      await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
            'userType': AppConstants.userTypeEmployee,
            'employeeId': employeeId,
            'employeeRequestData.status': 'approved',
            'employeeRequestData.approvedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Employee approved (ID: $employeeId)')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to approve: $e')));
      }
    }
  }

  Future<String> _generateUniqueEmployeeId() async {
    const min = 100000;
    const max = 999999;
    final rand = Random.secure();

    for (int i = 0; i < 10; i++) {
      final candidate = (min + rand.nextInt(max - min + 1)).toString();
      final clash = await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .where('employeeId', isEqualTo: candidate)
          .limit(1)
          .get();
      if (clash.docs.isEmpty) {
        return candidate;
      }
    }

    return (min + rand.nextInt(max - min + 1)).toString();
  }

  Future<void> _rejectEmployee(BuildContext context, String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
            'userType': AppConstants.userTypeTempEmployee,
            'employeeRequestData': FieldValue.delete(),
            'adminId': FieldValue.delete(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Employee request rejected')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to reject: $e')));
      }
    }
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
