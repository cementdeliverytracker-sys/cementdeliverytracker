import 'package:cementdeliverytracker/core/constants/app_constants.dart';
import 'package:cementdeliverytracker/features/auth/presentation/providers/auth_notifier.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PendingApprovalPage extends StatelessWidget {
  const PendingApprovalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthNotifier>().user;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(user.id)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final userType = userData?['userType'] ?? AppConstants.userTypePending;
        final isEmployeeRequest =
            userType == AppConstants.userTypePendingEmployee;

        return _buildPendingPage(context, user, isEmployeeRequest);
      },
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
              await context.read<AuthNotifier>().logout();
              if (context.mounted) {
                navigator.pushNamedAndRemoveUntil('/login', (route) => false);
              }
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
