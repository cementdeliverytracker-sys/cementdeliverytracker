import 'package:cementdeliverytracker/core/constants/app_constants.dart';
import 'package:cementdeliverytracker/core/utils/app_utils.dart';
import 'package:cementdeliverytracker/features/auth/presentation/providers/auth_notifier.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  Future<void> _handleRejectUser(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'userType': AppConstants.userTypeTempEmployee,
        'adminRequestData': FieldValue.delete(),
      });
      if (mounted) {
        AppUtils.showSnackBar(context, 'Admin request rejected');
      }
    } catch (e) {
      if (mounted) {
        AppUtils.showSnackBar(context, 'Failed to reject: $e');
      }
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
                    ? const Center(
                        child: Text(
                          'No pending approvals',
                          style: TextStyle(color: Colors.white60, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(
                          AppConstants.defaultPadding,
                        ),
                        itemCount: dashboardProvider.pendingUsers.length,
                        itemBuilder: (ctx, index) {
                          final user = dashboardProvider.pendingUsers[index];
                          return StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.userId)
                                .snapshots(),
                            builder: (context, snapshot) {
                              final data =
                                  snapshot.data?.data()
                                      as Map<String, dynamic>?;
                              final adminRequestData =
                                  data?['adminRequestData']
                                      as Map<String, dynamic>?;
                              final companyName =
                                  adminRequestData?['companyName'] ?? 'N/A';
                              final reason =
                                  adminRequestData?['reason'] ?? 'N/A';
                              final requestedAt =
                                  adminRequestData?['requestedAt']
                                      as Timestamp?;

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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: const Color(
                                              0xFFFF6F00,
                                            ),
                                            radius: 24,
                                            child: Text(
                                              user.username[0].toUpperCase(),
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
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  user.username,
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                Text(
                                                  user.email,
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
                                      const SizedBox(height: 16),
                                      const Divider(color: Colors.white24),
                                      const SizedBox(height: 12),
                                      _InfoRow(
                                        icon: Icons.business,
                                        label: 'Company Name',
                                        value: companyName,
                                      ),
                                      const SizedBox(height: 8),
                                      _InfoRow(
                                        icon: Icons.description,
                                        label: 'Reason',
                                        value: reason,
                                      ),
                                      if (requestedAt != null) ...[
                                        const SizedBox(height: 8),
                                        _InfoRow(
                                          icon: Icons.schedule,
                                          label: 'Requested',
                                          value: _formatTimestamp(requestedAt),
                                        ),
                                      ],
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          OutlinedButton.icon(
                                            onPressed: () =>
                                                _handleRejectUser(user.userId),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.red,
                                              side: const BorderSide(
                                                color: Colors.red,
                                              ),
                                            ),
                                            icon: const Icon(
                                              Icons.close,
                                              size: 18,
                                            ),
                                            label: const Text('Reject'),
                                          ),
                                          const SizedBox(width: 12),
                                          ElevatedButton.icon(
                                            onPressed: () =>
                                                _handleApproveUser(user.userId),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFFFF6F00,
                                              ),
                                              foregroundColor: Colors.white,
                                            ),
                                            icon: const Icon(
                                              Icons.check_circle,
                                              size: 18,
                                            ),
                                            label: const Text(
                                              'Approve as Admin',
                                            ),
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
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 0) {
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFFFF6F00)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
