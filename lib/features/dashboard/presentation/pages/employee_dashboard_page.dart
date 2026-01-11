import 'package:cementdeliverytracker/features/auth/presentation/providers/auth_notifier.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EmployeeDashboardPage extends StatefulWidget {
  const EmployeeDashboardPage({super.key});

  @override
  State<EmployeeDashboardPage> createState() => _EmployeeDashboardPageState();
}

class _EmployeeDashboardPageState extends State<EmployeeDashboardPage> {
  @override
  void initState() {
    super.initState();
    final user = context.read<AuthNotifier>().user;
    if (user != null) {
      context.read<DashboardProvider>().loadUserData(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Dashboard'),
        actions: [
          IconButton(
            onPressed: () async {
              await context.read<AuthNotifier>().logout();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, dashboardProvider, child) {
          final userData = dashboardProvider.userData;

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Welcome Employee!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                if (userData != null) ...[
                  Text(
                    'Username: ${userData.username}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Email: ${userData.email}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'View your tasks and track deliveries.',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ] else if (dashboardProvider.state ==
                    DashboardState.loading) ...[
                  const CircularProgressIndicator(),
                ] else if (dashboardProvider.errorMessage != null) ...[
                  Text(
                    'Error: ${dashboardProvider.errorMessage}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
