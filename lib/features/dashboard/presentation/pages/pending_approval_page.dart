import 'package:cementdeliverytracker/features/auth/presentation/providers/auth_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PendingApprovalPage extends StatelessWidget {
  const PendingApprovalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthNotifier>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Approval'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () async {
              await context.read<AuthNotifier>().logout();
            },
            icon: const Icon(Icons.logout),
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
              const Text(
                'Account Pending Approval',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Text(
                'Welcome ${user?.displayName ?? user?.email ?? 'User'}!',
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                'Your account is currently pending approval from a Super Admin. '
                'You will be notified once your account is approved.',
                style: TextStyle(fontSize: 16),
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
