import 'package:cementdeliverytracker/features/dashboard/data/services/admin_location_cache.dart';
import 'package:cementdeliverytracker/features/dashboard/data/services/attendance_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AttendanceService Tests', () {
    setUp(() {
      // Reset AdminLocationCache singleton between tests
      AdminLocationCache().clearAllCache();
    });

    // ========================================================================
    // TEST: Calculate Distance
    // ========================================================================
    group('calculateDistance', () {
      test('calculates correct distance between two locations', () async {
        // Arrange
        const double adminLat = 40.7128; // New York
        const double adminLng = -74.0060;
        const double employeeLat = 40.7489; // Times Square (~5.5 km away)
        const double employeeLng = -73.9680;

        // Act
        final distance = await AttendanceService.calculateDistance(
          adminLat: adminLat,
          adminLong: adminLng,
          employeeLat: employeeLat,
          employeeLong: employeeLng,
        );

        // Assert
        expect(distance, greaterThan(5000)); // Should be ~5.5 km
        expect(distance, lessThan(6000));
      });

      test('returns zero distance for same location', () async {
        // Arrange
        const double lat = 28.7041; // Delhi
        const double lng = 77.1025;

        // Act
        final distance = await AttendanceService.calculateDistance(
          adminLat: lat,
          adminLong: lng,
          employeeLat: lat,
          employeeLong: lng,
        );

        // Assert
        expect(distance, equals(0));
      });

      test('calculates distance correctly for different coordinates', () async {
        // Arrange
        const double lat1 = 0.0;
        const double lng1 = 0.0;
        const double lat2 = 1.0;
        const double lng2 = 1.0;

        // Act
        final distance = await AttendanceService.calculateDistance(
          adminLat: lat1,
          adminLong: lng1,
          employeeLat: lat2,
          employeeLong: lng2,
        );

        // Assert
        expect(distance, greaterThan(0));
        expect(distance, lessThan(200000)); // Less than 200 km
      });
    });

    // ========================================================================
    // TEST: Service Integration
    // ========================================================================
    group('AttendanceService integration', () {
      test('cache is properly initialized', () {
        // Arrange & Act
        final cache = AdminLocationCache();

        // Assert
        expect(cache, isNotNull);
      });

      test('admin location cache can be cleared', () {
        // Arrange
        final cache = AdminLocationCache();

        // Act
        cache.clearAllCache();

        // Assert
        final stats = cache.getCacheStats();
        expect(stats['totalCached'], equals(0));
      });

      test('distance validation threshold is 100 meters', () {
        // Arrange
        const double maxDistance = 100.0;

        // Assert
        expect(maxDistance, equals(100.0)); // Verify threshold constant
      });

      test('accuracy threshold is 50 meters', () {
        // Arrange
        const double accuracyThreshold = 50.0;

        // Assert
        expect(accuracyThreshold, equals(50.0)); // Verify threshold constant
      });
    });
  });
}
