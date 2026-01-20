import 'package:cementdeliverytracker/core/constants/app_constants.dart';
import 'package:cementdeliverytracker/features/auth/presentation/providers/auth_notifier.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/pages/admin/pages/pending_employee_requests_page.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/pages/admin/services/admin_employee_service.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
                  stream: AdminEmployeeService().getEmployeesStream(userId),
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
                      return DashboardCard(
                        onTap: null,
                        child: Text(
                          'Failed to load employees: ${snapshot.error}',
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      );
                    }

                    final employeeCount = snapshot.data?.docs.length ?? 0;

                    return DashboardCard(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                EmployeesListFullPage(adminId: userId),
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
          _buildPendingRequestsBottomButton(userId),
        ],
      ),
    );
  }

  Widget _buildPendingRequestsBottomButton(String userId) {
    return FixedBottomButton(
      label: 'Pending Requests',
      icon: Icons.pending_actions,
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PendingEmployeeRequestsPage(adminId: userId),
          ),
        );
      },
    );
  }
}

class EmployeesListFullPage extends StatefulWidget {
  final String adminId;

  const EmployeesListFullPage({required this.adminId, super.key});

  @override
  State<EmployeesListFullPage> createState() => _EmployeesListFullPageState();
}

class _EmployeesListFullPageState extends State<EmployeesListFullPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Employees')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: AdminEmployeeService().getEmployeesStream(widget.adminId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingState();
          }

          if (snapshot.hasError) {
            return ErrorState(
              message: 'Failed to load employees: ${snapshot.error}',
            );
          }

          final employees = snapshot.data?.docs ?? [];

          if (employees.isEmpty) {
            return const EmptyState(
              message: 'No employees yet',
              icon: Icons.people_outline,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            itemCount: employees.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final doc = employees[index];
              final data = doc.data();

              return EmployeeCard(
                employeeData: data,
                onTap: () => _showEmployeeDetails(context, data),
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
                UserAvatar(name: name, radius: 24),
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
            DetailRow(label: 'Employee ID', value: employeeId),
            DetailRow(label: 'Email', value: email),
            DetailRow(label: 'Age', value: age),
            DetailRow(label: 'Phone', value: phone),
            DetailRow(label: 'Address', value: address),
            DetailRow(label: 'Role', value: role),
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
}

class EmployeeCard extends StatelessWidget {
  final Map<String, dynamic> employeeData;
  final VoidCallback onTap;

  const EmployeeCard({
    required this.employeeData,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final data = employeeData;
    final name = (data['username'] ?? 'Unnamed') as String;
    final email = (data['email'] ?? 'N/A') as String;
    final phone = (data['phone'] ?? 'N/A') as String;

    return DashboardCard(
      child: ListTile(
        leading: UserAvatar(name: name),
        title: Text(name, style: const TextStyle(color: Colors.white)),
        subtitle: Text(
          '$email • $phone',
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white70),
        onTap: onTap,
      ),
    );
  }
}
