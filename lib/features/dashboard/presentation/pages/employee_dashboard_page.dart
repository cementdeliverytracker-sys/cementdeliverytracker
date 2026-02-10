import 'package:cementdeliverytracker/core/theme/app_colors.dart';
import 'package:cementdeliverytracker/core/constants/app_constants.dart';
import 'package:cementdeliverytracker/core/services/employee_metadata_cache_service.dart';
import 'package:cementdeliverytracker/core/services/api_usage_monitoring_service.dart';
import 'package:cementdeliverytracker/features/auth/presentation/providers/auth_notifier.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/screens/employee_add_distributor_dialog.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/screens/employee_dashboard_screen.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/screens/employee_distributor_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cementdeliverytracker/shared/widgets/settings_screen.dart';

class EmployeeDashboardPage extends StatefulWidget {
  const EmployeeDashboardPage({super.key});

  @override
  State<EmployeeDashboardPage> createState() => _EmployeeDashboardPageState();
}

class _EmployeeDashboardPageState extends State<EmployeeDashboardPage> {
  int _currentIndex = 0;
  bool _isAttendanceExpanded = false;

  final List<Widget> _pages = [
    const EmployeeDashboardScreen(),
    const EmployeeDistributorListScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthNotifier>().user;
    if (user != null) {
      context.read<DashboardProvider>().loadUserData(user.id);
    }
  }

  Future<void> _openAddDistributorDialog() async {
    final user = context.read<AuthNotifier>().user;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not authenticated')));
      return;
    }

    try {
      // Use cached employee metadata service to reduce Firestore reads
      final metadataCache = context.read<EmployeeMetadataCacheService>();
      final apiMonitor = context.read<APIUsageMonitoringService>();

      final adminId = await metadataCache.getEmployeeAdminId(user.id);

      apiMonitor.recordFirestoreRead(
        collection: 'users',
        operation: 'getEmployeeAdminId',
      );

      if (adminId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No admin assigned to you')),
          );
        }
        return;
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => EmployeeAddDistributorDialog(adminId: adminId),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading admin info: $e')));
      }
    }
  }

  Widget _buildDistributorFAB() {
    return FloatingActionButton.extended(
      onPressed: _openAddDistributorDialog,
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      icon: const Icon(Icons.add),
      label: const Text('Add Distributor'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthNotifier>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Dashboard'),
        actions: [
          IconButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              final authNotifier = context.read<AuthNotifier>();
              await authNotifier.logout();
              if (!mounted) return;
              if (authNotifier.state == AuthState.unauthenticated) {
                navigator.pushNamedAndRemoveUntil(
                  AppConstants.routeLogin,
                  (route) => false,
                );
                return;
              }
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    authNotifier.errorMessage ??
                        'Logout failed. Please try again.',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              ExpansionTile(
                leading: const Icon(Icons.event_note),
                title: Text(
                  'Recent Attendance',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                initiallyExpanded: _isAttendanceExpanded,
                onExpansionChanged: (expanded) {
                  setState(() => _isAttendanceExpanded = expanded);
                },
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: user == null
                        ? Text(
                            'User not authenticated',
                            style: Theme.of(context).textTheme.bodySmall,
                          )
                        : AttendanceHistoryList(employeeId: user.id),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _pages[_currentIndex],
      floatingActionButton: _currentIndex == 1 ? _buildDistributorFAB() : null,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: AppColors.primary,
        unselectedItemColor:
            Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6) ??
            AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Distributors',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
