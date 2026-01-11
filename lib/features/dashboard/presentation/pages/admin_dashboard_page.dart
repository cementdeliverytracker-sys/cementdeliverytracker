import 'package:cementdeliverytracker/features/auth/presentation/providers/auth_notifier.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
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
        title: const Text('Admin Dashboard'),
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
                  'Welcome Admin!',
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
                    'Manage your team and oversee operations.',
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
