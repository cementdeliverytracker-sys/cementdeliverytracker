import 'package:cementdeliverytracker/core/constants/app_constants.dart';
import 'package:cementdeliverytracker/features/dashboard/domain/usecases/employee_usecases.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PendingEmployeeRequestsPage extends StatefulWidget {
  final String adminId;

  const PendingEmployeeRequestsPage({required this.adminId, super.key});

  @override
  State<PendingEmployeeRequestsPage> createState() =>
      _PendingEmployeeRequestsPageState();
}

class _PendingEmployeeRequestsPageState
    extends State<PendingEmployeeRequestsPage> {
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

  @override
  Widget build(BuildContext context) {
    final getPendingEmployeesUseCase = context
        .read<GetPendingEmployeesStreamUseCase>();

    return Scaffold(
      appBar: AppBar(title: const Text('Pending Employee Requests')),
      body: StreamBuilder<Object>(
        stream: getPendingEmployeesUseCase(widget.adminId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingState();
          }

          if (snapshot.hasError) {
            return ErrorState(message: 'Error loading requests');
          }

          // Handle Either type from use case
          final either = snapshot.data;
          if (either == null) {
            return const LoadingState();
          }

          // Extract QuerySnapshot from Either
          QuerySnapshot<Map<String, dynamic>>? querySnapshot;
          (either as dynamic).fold(
            (failure) => null,
            (data) => querySnapshot = data,
          );

          if (querySnapshot == null) {
            return ErrorState(message: 'Error loading requests');
          }

          final requests = querySnapshot!.docs;

          if (requests.isEmpty) {
            return const EmptyState(
              message: 'No pending requests',
              icon: Icons.inbox_outlined,
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
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                    ),
                              ),
                              Text(
                                email,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(fontSize: 14),
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
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(fontSize: 12),
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
    // Get employee name before approval
    String employeeName = 'Employee';
    try {
      final doc = await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();
      employeeName = (doc.data()?['username'] ?? 'Employee') as String;
    } catch (_) {}

    if (!mounted) return;

    final approveUseCase = context.read<ApproveEmployeeUseCase>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final result = await approveUseCase(
      userId: userId,
      adminId: widget.adminId,
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to approve: ${failure.message}')),
        );
      },
      (_) {
        showDialog(
          context: navigator.context,
          builder: (ctx) => AlertDialog(
            title: const Text('Success'),
            content: Text('$employeeName has been added successfully.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _rejectEmployee(BuildContext context, String userId) async {
    final rejectUseCase = context.read<RejectEmployeeUseCase>();

    final result = await rejectUseCase(userId);

    if (!context.mounted || !mounted) return;

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject: ${failure.message}')),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Employee request rejected')),
        );
      },
    );
  }
}
