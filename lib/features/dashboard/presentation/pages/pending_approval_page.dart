import 'package:cementdeliverytracker/core/constants/app_constants.dart';
import 'package:cementdeliverytracker/features/auth/presentation/providers/auth_notifier.dart';
import 'package:cementdeliverytracker/features/auth/presentation/pages/role_selection_page.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/pages/admin/pages/admin_dashboard_page.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/pages/employee_dashboard_page.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/pages/super_admin_dashboard_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PendingApprovalPage extends StatefulWidget {
  const PendingApprovalPage({super.key});

  @override
  State<PendingApprovalPage> createState() => _PendingApprovalPageState();
}

class _PendingApprovalPageState extends State<PendingApprovalPage> {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthNotifier>().user;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(user.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text(
                    'Checking your approval status...',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorPage();
        }

        final userData = snapshot.data?.data();
        final userType =
            (userData?['userType'] as String?) ?? AppConstants.userTypePending;
        final isEmployeeRequest =
            userType == AppConstants.userTypePendingEmployee;

        switch (userType) {
          case AppConstants.userTypeSuperAdmin:
            return const SuperAdminDashboardPage();
          case AppConstants.userTypeAdmin:
            return const AdminDashboardPage();
          case AppConstants.userTypeEmployee:
            return const EmployeeDashboardPage();
          case AppConstants.userTypeTempEmployee:
            return const RoleSelectionPage();
          case AppConstants.userTypePending:
          case AppConstants.userTypePendingEmployee:
            break;
          default:
            break;
        }

        return _buildPendingPage(context, user, isEmployeeRequest);
      },
    );
  }

  Scaffold _buildErrorPage() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              const Text(
                'Unable to check approval status. Please try again.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => setState(() {}),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Scaffold _buildPendingPage(
    BuildContext context,
    dynamic user,
    bool isEmployeeRequest,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Approval'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              final authNotifier = context.read<AuthNotifier>();
              await authNotifier.logout();
              if (!context.mounted) return;
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
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_empty, size: 80, color: Colors.orange),
              const SizedBox(height: 20),
              Text(
                isEmployeeRequest
                    ? 'Employee Request Pending'
                    : 'Account Pending Approval',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Welcome ${user?.displayName ?? user?.email ?? 'User'}!',
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                isEmployeeRequest
                    ? 'Your request to join as an employee has been sent to the admin. '
                          'You will be notified once the admin approves your request.'
                    : 'Your account is currently pending approval from a Super Admin. '
                          'You will be notified once your account is approved.',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              const Text(
                'Please check back later or contact support if you have any questions.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
