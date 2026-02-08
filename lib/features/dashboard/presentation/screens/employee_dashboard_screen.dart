import 'package:cementdeliverytracker/core/constants/app_constants.dart';
import 'package:cementdeliverytracker/core/theme/app_colors.dart';
import 'package:cementdeliverytracker/features/auth/presentation/providers/auth_notifier.dart';
import 'package:cementdeliverytracker/features/dashboard/data/exceptions/location_exceptions.dart';
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
        final username = (userData?['username'] as String? ?? 'Employee')
            .toUpperCase();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, $username',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('MMMM d, yyyy').format(DateTime.now()),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Daily Check-in',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                hasLoggedInToday
                    ? 'Today\'s Attendance'
                    : 'Mark your attendance today',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),

              // Attendance Status Card - Only show if logged in
              if (hasLoggedInToday) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green, width: 2),
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
                                      ?.withValues(alpha: 0.7) ??
                                  AppColors.textSecondary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Logged In',
                              style: TextStyle(
                                color: Colors.green,
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
                                    ?.withValues(alpha: 0.7) ??
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
                                    ?.withValues(alpha: 0.7) ??
                                AppColors.textSecondary,
                          ),
                        ),
                      ] else
                        const Text(
                          'Login recorded today',
                          style: TextStyle(fontSize: 14, color: Colors.green),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Stamp Login Button - Only show if NOT logged in
              if (!hasLoggedInToday) ...[
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isStamping
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
                      _isStamping ? 'Stamping Login...' : 'Stamp Login',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),

                // Info Box
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.3),
                    ),
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
              ],
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  /// Optimized stamp login with GPS timeout, fallback, accuracy check, and error handling
  Future<void> _stampLogin(BuildContext context, String employeeId) async {
    setState(() => _isStamping = true);

    try {
      // Step 1: Request and validate location permission
      final position = await _getLocationWithValidation();

      // Step 2: Get admin ID from user document
      final userDoc = await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(employeeId)
          .get();

      if (!mounted) return;

      if (!userDoc.exists || userDoc.data() == null) {
        throw Exception('User data not found');
      }

      final adminId = userDoc.data()?['adminId'] as String?;
      if (adminId == null) {
        throw Exception('Admin ID not found');
      }

      // Step 3: Create attendance log with atomic transaction
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
            duration: Duration(seconds: 2),
          ),
        );
      }
    } on LocationException catch (e) {
      // User-friendly error messages for location-specific errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.userMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      // Generic error handling
      if (mounted) {
        final errorMessage = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isStamping = false);
      }
    }
  }

  /// Get location with timeout, fallback, and accuracy validation
  /// Returns Position if successful, throws LocationException otherwise
  Future<Position> _getLocationWithValidation() async {
    // Step 1: Check location permission
    await _checkLocationPermission();

    // Step 2: Try GPS with 10-second timeout
    try {
      final position =
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 10),
            ),
          ).timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw GPSTimeoutException(),
          );

      // Step 3: Validate accuracy threshold (<50 meters)
      await _validateLocationAccuracy(position);

      // Step 4: Validate location coordinates
      _validateLocationCoordinates(position.latitude, position.longitude);

      return position;
    } on GPSTimeoutException {
      // GPS timed out, try fallback (currently unavailable, but shows error)
      throw GPSTimeoutException();
    } on LocationAccuracyException {
      // Location accuracy too poor, show error
      rethrow;
    } catch (e) {
      // GPS failed, try fallback
      throw GPSTimeoutException();
    }
  }

  /// Check and request location permission if needed
  /// Throws LocationPermissionException if permission denied
  Future<LocationPermission> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationPermissionException(isPermanent: false);
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationPermissionException(isPermanent: true);
    }

    if (!await Geolocator.isLocationServiceEnabled()) {
      throw NoLocationServiceException();
    }

    return permission;
  }

  /// Validate location accuracy threshold
  /// Throws LocationAccuracyException if accuracy > 50 meters
  Future<void> _validateLocationAccuracy(Position position) async {
    const double accuracyThreshold = 50.0;

    if (position.accuracy > accuracyThreshold) {
      throw LocationAccuracyException(position.accuracy);
    }

    // Warn if accuracy is moderate (30-50 meters)
    if (position.accuracy > 30 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Location accuracy is moderate (±${position.accuracy.toStringAsFixed(0)}m). '
            'For best results, ensure clear sky view.',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Validate location coordinates are within valid range
  /// Throws InvalidLocationException if coordinates are invalid
  void _validateLocationCoordinates(double latitude, double longitude) {
    if (latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      throw InvalidLocationException(latitude, longitude);
    }
  }
}

class AttendanceHistoryList extends StatelessWidget {
  final String employeeId;

  const AttendanceHistoryList({super.key, required this.employeeId});

  @override
  Widget build(BuildContext context) {
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
            style:
                Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.white60) ??
                const TextStyle(color: Colors.white60),
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
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                ),
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
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white60),
                  ),
                  if (distance > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Distance: ${distance.toStringAsFixed(2)} m',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
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
