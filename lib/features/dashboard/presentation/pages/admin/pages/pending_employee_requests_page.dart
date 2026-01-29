import 'package:cementdeliverytracker/core/constants/app_constants.dart';
import 'package:cementdeliverytracker/core/theme/app_colors.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/pages/admin/services/admin_employee_service.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PendingEmployeeRequestsPage extends StatefulWidget {
  final String adminId;

  const PendingEmployeeRequestsPage({required this.adminId, super.key});

  @override
  State<PendingEmployeeRequestsPage> createState() =>
      _PendingEmployeeRequestsPageState();
}

class _PendingEmployeeRequestsPageState
    extends State<PendingEmployeeRequestsPage> {
  late final AdminEmployeeService _employeeService = AdminEmployeeService();

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      debugPrint('DEBUG: Querying for adminId: ${widget.adminId}');
      debugPrint(
        'DEBUG: Looking for userType: ${AppConstants.userTypePendingEmployee}',
      );
    }
  }

  Future<void> _showDebugInfo(BuildContext context) async {
    try {
      final allPendingEmployees = await _employeeService
          .getAllPendingEmployees();

      if (!mounted || !context.mounted) return;

      if (kDebugMode) {
        debugPrint(
          'DEBUG: Total pending_employee users: ${allPendingEmployees.docs.length}',
        );
      }

      final buffer = StringBuffer('All Pending Employees:\n\n');
      for (final doc in allPendingEmployees.docs) {
        final data = doc.data();
        buffer
          ..writeln('User: ${data['username'] ?? 'Unknown'}')
          ..writeln('AdminId: ${data['adminId'] ?? 'NOT SET'}')
          ..writeln('UserType: ${data['userType']}')
          ..writeln('Email: ${data['email'] ?? 'N/A'}')
          ..writeln('---');

        if (kDebugMode) {
          debugPrint(
            'DEBUG User: ${data['username']}, AdminId: ${data['adminId']}, UserType: ${data['userType']}',
          );
        }
      }

      if (!mounted || !context.mounted) return;

      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Debug Info'),
          content: SingleChildScrollView(child: Text(buffer.toString())),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DEBUG ERROR: $e');
      }
      if (!mounted || !context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pending Employee Requests')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _employeeService.getPendingEmployeesStream(widget.adminId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingState();
          }

          if (snapshot.hasError) {
            return ErrorState(message: 'Error loading requests');
          }

          final requests = snapshot.data?.docs ?? [];

          if (requests.isEmpty) {
            return EmptyState(
              message: 'No pending requests',
              icon: Icons.inbox_outlined,
              action: ElevatedButton(
                onPressed: () => _showDebugInfo(context),
                child: const Text('Show Debug Info'),
              ),
            );
          }

          final sortedRequests = List<QueryDocumentSnapshot>.from(requests);
          sortedRequests.sort((a, b) {
            final aTime =
                (a.get('employeeRequestData')?['requestedAt'] as Timestamp?) ??
                Timestamp.now();
            final bTime =
                (b.get('employeeRequestData')?['requestedAt'] as Timestamp?) ??
                Timestamp.now();
            return bTime.compareTo(aTime);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            itemCount: sortedRequests.length,
            itemBuilder: (context, index) {
              final request = sortedRequests[index];
              final data = request.data() as Map<String, dynamic>;
              final username = data['username'] ?? 'Unknown';
              final email = data['email'] ?? 'N/A';
              final requestedAt =
                  (data['employeeRequestData']?['requestedAt'] as Timestamp?)
                      ?.toDate();

              return DashboardCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        UserAvatar(name: username, radius: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                username,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                email,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (requestedAt != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Requested: ${requestedAt.toString().split('.')[0]}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    ActionButtonsRow(
                      onReject: () => _rejectEmployee(context, request.id),
                      onApprove: () => _approveEmployee(context, request.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _approveEmployee(BuildContext context, String userId) async {
    try {
      await _employeeService.approveEmployee(userId);
    } catch (e) {
      if (!context.mounted || !mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to approve: $e')));
      return;
    }

    if (!context.mounted || !mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Employee approved')));
  }

  Future<void> _rejectEmployee(BuildContext context, String userId) async {
    try {
      await _employeeService.rejectEmployee(userId);
    } catch (e) {
      if (!context.mounted || !mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to reject: $e')));
      return;
    }

    if (!context.mounted || !mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Employee request rejected')));
  }
}
