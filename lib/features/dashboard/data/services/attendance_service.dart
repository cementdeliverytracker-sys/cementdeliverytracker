import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cementdeliverytracker/core/constants/app_constants.dart';
import 'package:cementdeliverytracker/features/dashboard/data/exceptions/location_exceptions.dart';
import 'package:cementdeliverytracker/features/dashboard/data/services/admin_location_cache.dart';

class AttendanceService {
  static const double _maxDistanceMeters = 100;
  // Note: IST timezone offset is +5:30, handled directly in time calculations

  /// Get today's date in IST timezone
  static DateTime _getISTToday() {
    final now = DateTime.now();
    // IST is UTC+5:30
    final istDateTime = now.add(const Duration(hours: 5, minutes: 30));
    return DateTime(istDateTime.year, istDateTime.month, istDateTime.day);
  }

  /// Calculate distance between two coordinates in meters
  static Future<double> calculateDistance({
    required double adminLat,
    required double adminLong,
    required double employeeLat,
    required double employeeLong,
  }) async {
    return Geolocator.distanceBetween(
      adminLat,
      adminLong,
      employeeLat,
      employeeLong,
    );
  }

  /// Get admin's enterprise location with caching
  /// Uses in-memory cache with 24-hour TTL to reduce Firestore reads
  static Future<Map<String, dynamic>> getAdminLocation(String adminId) async {
    try {
      return await AdminLocationCache().getAdminLocation(adminId);
    } catch (e) {
      rethrow;
    }
  }

  /// Check if employee has already logged in today
  static Future<bool> hasLoggedInToday(String employeeId) async {
    try {
      final today = _getISTToday();
      final tomorrow = today.add(const Duration(days: 1));

      final query = await FirebaseFirestore.instance
          .collection(AppConstants.attendanceLogsCollection)
          .where('employeeId', isEqualTo: employeeId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .where('timestamp', isLessThan: Timestamp.fromDate(tomorrow))
          .count()
          .get();

      return query.count! > 0;
    } catch (e) {
      rethrow;
    }
  }

  /// Create attendance log entry
  static Future<bool> createAttendanceLog({
    required String employeeId,
    required String adminId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Use Firestore transaction for atomic consistency
      return await FirebaseFirestore.instance.runTransaction<bool>((
        transaction,
      ) async {
        // === READ PHASE ===
        // Fetch user document
        final userDocRef = FirebaseFirestore.instance
            .collection(AppConstants.usersCollection)
            .doc(employeeId);
        final userDoc = await transaction.get(userDocRef);

        if (!userDoc.exists) {
          throw Exception('User not found');
        }

        final userStatus =
            (userDoc.data()?['status'] ?? 'logged_out') as String;

        // Get admin's location from cache
        final adminLocation = await getAdminLocation(adminId);
        final adminLat = adminLocation['latitude'] as double;
        final adminLong = adminLocation['longitude'] as double;

        // Validate location coordinates
        if (adminLat < -90 ||
            adminLat > 90 ||
            adminLong < -180 ||
            adminLong > 180) {
          throw InvalidLocationException(adminLat, adminLong);
        }

        // Calculate distance between employee and admin location
        final distance = await calculateDistance(
          adminLat: adminLat,
          adminLong: adminLong,
          employeeLat: latitude,
          employeeLong: longitude,
        );

        // === VALIDATION PHASE ===
        // Re-enabled: Check if within allowed distance
        if (distance > _maxDistanceMeters) {
          throw LocationOutOfRangeException(
            distance: distance,
            maxDistance: _maxDistanceMeters,
          );
        }

        // Check if already logged in today (unless force logged out)
        final alreadyLoggedIn = await hasLoggedInToday(employeeId);
        final wasForceLoggedOut = userStatus == 'logged_out';
        if (alreadyLoggedIn && !wasForceLoggedOut) {
          throw AlreadyLoggedInException();
        }

        // === WRITE PHASE ===
        // Both writes succeed or both fail (atomic)
        // Create attendance log document
        final attendanceRef = FirebaseFirestore.instance
            .collection(AppConstants.attendanceLogsCollection)
            .doc();

        transaction.set(attendanceRef, {
          'employeeId': employeeId,
          'adminId': adminId,
          'timestamp': FieldValue.serverTimestamp(),
          'location': {
            'latitude': latitude,
            'longitude': longitude,
            'adminLatitude': adminLat,
            'adminLongitude': adminLong,
            'distance': distance,
          },
          'status': 'logged_in',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Update user status to logged_in (atomic with attendance log)
        transaction.update(userDocRef, {
          'status': 'logged_in',
          'lastLoginTime': FieldValue.serverTimestamp(),
        });

        return true;
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Get today's attendance for employee
  static Future<DocumentSnapshot<Map<String, dynamic>>?> getTodayAttendance(
    String employeeId,
  ) async {
    try {
      final today = _getISTToday();
      final tomorrow = today.add(const Duration(days: 1));

      final querySnapshot = await FirebaseFirestore.instance
          .collection(AppConstants.attendanceLogsCollection)
          .where('employeeId', isEqualTo: employeeId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .where('timestamp', isLessThan: Timestamp.fromDate(tomorrow))
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Get attendance logs for employee in date range
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAttendanceLogsStream(
    String employeeId, {
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return FirebaseFirestore.instance
        .collection(AppConstants.attendanceLogsCollection)
        .where('employeeId', isEqualTo: employeeId)
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        )
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Get attendance summary for admin
  static Stream<QuerySnapshot<Map<String, dynamic>>>
  getAdminAttendanceLogsStream(String adminId, {required DateTime date}) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return FirebaseFirestore.instance
        .collection(AppConstants.attendanceLogsCollection)
        .where('adminId', isEqualTo: adminId)
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
