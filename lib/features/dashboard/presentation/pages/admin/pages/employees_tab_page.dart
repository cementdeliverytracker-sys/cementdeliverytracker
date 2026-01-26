import 'package:cementdeliverytracker/core/constants/app_constants.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/pages/admin/pages/pending_employee_requests_page.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/pages/admin/services/admin_employee_service.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// EmployeesTabPage displays the Employees tab content with overview card and pending requests button.
class EmployeesTabPage extends StatelessWidget {
  final String userId;
  final AdminEmployeeService _employeeService = AdminEmployeeService();

  EmployeesTabPage({required this.userId, super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppConstants.defaultPadding,
            right: AppConstants.defaultPadding,
            top: AppConstants.defaultPadding,
            bottom: 90,
          ),
          child: ListView(
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
                stream: _employeeService.getEmployeesStream(userId),
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

                  final memberCount = snapshot.data?.docs.length ?? 0;

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
                              '$memberCount approved',
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
            ],
          ),
        ),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _employeeService.getPendingEmployeesStream(userId),
          builder: (context, pendingSnapshot) {
            final pendingCount = pendingSnapshot.data?.docs.length ?? 0;
            return Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2C),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
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
                          builder: (_) =>
                              PendingEmployeeRequestsPage(adminId: userId),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6F00),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    icon: const Icon(Icons.pending_actions, size: 20),
                    label: Text(
                      'Pending Request${pendingCount != 1 ? 's' : ''} ($pendingCount)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// EmployeesListFullPage displays the complete list of employees with details.
class EmployeesListFullPage extends StatefulWidget {
  final String adminId;

  const EmployeesListFullPage({required this.adminId, super.key});

  @override
  State<EmployeesListFullPage> createState() => _EmployeesListFullPageState();
}

class _EmployeesListFullPageState extends State<EmployeesListFullPage> {
  final AdminEmployeeService _employeeService = AdminEmployeeService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Employees')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _employeeService.getEmployeesStream(widget.adminId),
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
                onTap: () => _showEmployeeDetails(context, data, doc.id),
              );
            },
          );
        },
      ),
    );
  }

  void _showEmployeeDetails(
    BuildContext context,
    Map<String, dynamic> data,
    String userId,
  ) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _confirmRemoveEmployee(context, userId);
                  },
                  icon: const Icon(Icons.person_remove_alt_1),
                  label: const Text('Remove'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRemoveEmployee(
    BuildContext context,
    String userId,
  ) async {
    final confirm =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Remove employee?'),
            content: const Text(
              'This will move the employee back to the approval queue. You can approve them again later.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Remove'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm || !mounted) return;

    try {
      await _employeeService.removeEmployee(
        userId: userId,
        adminId: widget.adminId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Employee moved to approvals')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to remove: $e')));
    }
  }
}

/// EmployeeCard displays a single employee in list view.
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
    final status = (data['status'] ?? 'logged_out') as String;
    final isLoggedIn = status == 'logged_in';

    return DashboardCard(
      child: ListTile(
        leading: UserAvatar(name: name),
        title: Row(
          children: [
            Expanded(
              child: Text(name, style: const TextStyle(color: Colors.white)),
            ),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: isLoggedIn ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
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
