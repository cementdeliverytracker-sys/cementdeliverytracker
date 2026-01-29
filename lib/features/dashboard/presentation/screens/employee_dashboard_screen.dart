import 'package:cementdeliverytracker/core/constants/app_constants.dart';
import 'package:cementdeliverytracker/core/theme/app_colors.dart';
import 'package:cementdeliverytracker/features/auth/presentation/providers/auth_notifier.dart';
import 'package:cementdeliverytracker/features/dashboard/data/services/attendance_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  State<EmployeeDashboardScreen> createState() =>
      _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  bool _isStamping = false;

  @override
  Widget build(BuildContext context) {
    final authNotifier = context.read<AuthNotifier>();
    final currentUser = authNotifier.user;

    if (currentUser == null) {
      return const Center(
        child: Text(
          'User not authenticated',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    // Stream the user's current status in real-time
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(currentUser.id)
          .snapshots(),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data();
        final status = (userData?['status'] ?? 'logged_out') as String;
        final hasLoggedInToday = status == 'logged_in';
        final todayLoginTime = (userData?['lastLoginTime'] as Timestamp?)
            ?.toDate();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, Employee',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('MMMM d, yyyy').format(DateTime.now()),
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              Text(
                'Daily Check-in',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Today\'s Attendance',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              // Attendance Status Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasLoggedInToday
                        ? Colors.green
                        : Colors.orange.withValues(alpha:  0.5),
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Status',
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color
                                    ?.withValues(alpha:  0.7) ??
                                AppColors.textSecondary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: hasLoggedInToday
                                ? Colors.green.withValues(alpha:  0.2)
                                : Colors.orange.withValues(alpha:  0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            hasLoggedInToday ? 'Logged In' : 'Not Logged In',
                            style: TextStyle(
                              color: hasLoggedInToday
                                  ? Colors.green
                                  : Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (todayLoginTime != null) ...[
                      Text(
                        'Login Time',
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color
                                  ?.withValues(alpha:  0.7) ??
                              AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('hh:mm a').format(todayLoginTime),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color:
                              Theme.of(context).textTheme.bodyLarge?.color ??
                              AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMMM d, yyyy').format(todayLoginTime),
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color
                                  ?.withValues(alpha:  0.7) ??
                              AppColors.textSecondary,
                        ),
                      ),
                    ] else if (hasLoggedInToday)
                      Text(
                        'Login recorded today',
                        style: TextStyle(fontSize: 14, color: Colors.green),
                      )
                    else
                      Text(
                        'You haven\'t logged in today yet',
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color
                                  ?.withValues(alpha:  0.7) ??
                              AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Stamp Login Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: (_isStamping || hasLoggedInToday)
                      ? null
                      : () => _stampLogin(context, currentUser.id),
                  icon: _isStamping
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.location_on),
                  label: Text(
                    hasLoggedInToday
                        ? 'Already Logged In Today'
                        : (_isStamping ? 'Stamping Login...' : 'Stamp Login'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasLoggedInToday
                        ? Colors.grey
                        : AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Info Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info, color: Colors.blue, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Make sure you are within 100 meters of your workplace to stamp your login.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Attendance History
              const Text(
                'Recent Attendance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              _buildAttendanceHistory(currentUser.id),
            ],
          ),
        );
      },
    );
  }

  Future<void> _stampLogin(BuildContext context, String employeeId) async {
    setState(() => _isStamping = true);

    try {
      // Request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied')),
            );
          }
          setState(() => _isStamping = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permission denied permanently. Please enable it in settings.',
              ),
            ),
          );
        }
        setState(() => _isStamping = false);
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // Get admin ID from user document
      final userDoc = await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(employeeId)
          .get();

      if (!mounted) return;

      if (!userDoc.exists || userDoc.data() == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User data not found')));
        setState(() => _isStamping = false);
        return;
      }

      final adminId = userDoc.data()?['adminId'] as String?;
      if (adminId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Admin ID not found')));
        setState(() => _isStamping = false);
        return;
      }

      // Create attendance log
      await AttendanceService.createAttendanceLog(
        employeeId: employeeId,
        adminId: adminId,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login stamped successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isStamping = false);
    }
  }

  Widget _buildAttendanceHistory(String employeeId) {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: AttendanceService.getAttendanceLogsStream(
        employeeId,
        startDate: thirtyDaysAgo,
        endDate: now,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Text(
            'Error: ${snapshot.error}',
            style: const TextStyle(color: Colors.red),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Text(
            'No attendance records yet',
            style: TextStyle(color: Colors.white60),
          );
        }

        final attendanceLogs = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: attendanceLogs.length,
          itemBuilder: (context, index) {
            final log = attendanceLogs[index].data();
            final timestamp = (log['timestamp'] as Timestamp?)?.toDate();
            final location = log['location'] as Map<String, dynamic>?;
            final distance = (location?['distance'] as num?)?.toDouble() ?? 0.0;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        timestamp != null
                            ? DateFormat('MMM d').format(timestamp)
                            : 'Unknown Date',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Logged In',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    timestamp != null
                        ? DateFormat('hh:mm a').format(timestamp)
                        : 'Unknown Time',
                    style: const TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                  if (distance > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Distance: ${distance.toStringAsFixed(2)} m',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
