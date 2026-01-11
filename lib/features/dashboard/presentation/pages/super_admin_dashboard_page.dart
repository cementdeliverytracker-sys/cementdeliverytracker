import 'package:cementdeliverytracker/core/constants/app_constants.dart';
import 'package:cementdeliverytracker/core/utils/app_utils.dart';
import 'package:cementdeliverytracker/features/auth/presentation/providers/auth_notifier.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SuperAdminDashboardPage extends StatefulWidget {
  const SuperAdminDashboardPage({super.key});

  @override
  State<SuperAdminDashboardPage> createState() =>
      _SuperAdminDashboardPageState();
}

class _SuperAdminDashboardPageState extends State<SuperAdminDashboardPage> {
  @override
  void initState() {
    super.initState();
    final user = context.read<AuthNotifier>().user;
    if (user != null) {
      context.read<DashboardProvider>().loadUserData(user.id);
      context.read<DashboardProvider>().listenToPendingUsers();
    }
  }

  Future<void> _handleApproveUser(String userId) async {
    await context.read<DashboardProvider>().approveUser(userId);
    if (mounted) {
      AppUtils.showSnackBar(context, 'User approved as Admin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Dashboard'),
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

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome Super Admin!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (userData != null) ...[
                      Text('Username: ${userData.username}'),
                      Text('Email: ${userData.email}'),
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
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.all(AppConstants.defaultPadding),
                child: Text(
                  'Pending User Approvals',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: dashboardProvider.pendingUsers.isEmpty
                    ? const Center(child: Text('No pending approvals'))
                    : ListView.builder(
                        itemCount: dashboardProvider.pendingUsers.length,
                        itemBuilder: (ctx, index) {
                          final user = dashboardProvider.pendingUsers[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: AppConstants.defaultPadding,
                              vertical: 8,
                            ),
                            child: ListTile(
                              title: Text(user.username),
                              subtitle: Text(user.email),
                              trailing: ElevatedButton(
                                onPressed: () =>
                                    _handleApproveUser(user.userId),
                                child: const Text('Approve as Admin'),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
