import 'package:cementdeliverytracker/features/dashboard/data/exceptions/location_exceptions.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for custom location exception classes
/// Verifies user-friendly messaging and exception behavior
void main() {
  group('LocationException Tests', () {
    // ========================================================================
    // TEST: GPSTimeoutException
    // ========================================================================
    group('GPSTimeoutException', () {
      test('has correct technical message', () {
        // Arrange
        final exception = GPSTimeoutException();

        // Assert
        expect(exception.message, equals('GPS timeout after 10 seconds'));
      });

      test('has user-friendly message', () {
        // Arrange
        final exception = GPSTimeoutException();

        // Assert
        expect(exception.userMessage, contains('GPS is taking too long'));
        expect(exception.userMessage, contains('location services'));
      });

      test('is an instance of LocationException', () {
        // Arrange
        final exception = GPSTimeoutException();

        // Assert
        expect(exception, isA<LocationException>());
      });

      test('toString returns technical message', () {
        // Arrange
        final exception = GPSTimeoutException();

        // Assert
        expect(exception.toString(), equals('GPS timeout after 10 seconds'));
      });
    });

    // ========================================================================
    // TEST: LocationAccuracyException
    // ========================================================================
    group('LocationAccuracyException', () {
      test('stores accuracy value', () {
        // Arrange
        const double accuracy = 75.5;

        // Act
        final exception = LocationAccuracyException(accuracy);

        // Assert
        expect(exception.accuracy, equals(75.5));
      });

      test('includes accuracy in technical message', () {
        // Arrange
        const double accuracy = 75.5;

        // Act
        final exception = LocationAccuracyException(accuracy);

        // Assert
        expect(exception.message, contains('75.5'));
        expect(exception.message, contains('50 meters'));
      });

      test('includes formatted accuracy in user message', () {
        // Arrange
        const double accuracy = 75.5;

        // Act
        final exception = LocationAccuracyException(accuracy);

        // Assert
        expect(exception.userMessage, contains('±76 meters'));
        expect(exception.userMessage, contains('open area'));
      });

      test('formats accuracy correctly for whole numbers', () {
        // Arrange
        const double accuracy = 50.0;

        // Act
        final exception = LocationAccuracyException(accuracy);

        // Assert
        expect(exception.userMessage, contains('±50 meters'));
      });

      test('is instance of LocationException', () {
        // Arrange
        final exception = LocationAccuracyException(60.0);

        // Assert
        expect(exception, isA<LocationException>());
      });
    });

    // ========================================================================
    // TEST: NoLocationServiceException
    // ========================================================================
    group('NoLocationServiceException', () {
      test('has appropriate technical message', () {
        // Arrange
        final exception = NoLocationServiceException();

        // Assert
        expect(exception.message, contains('No location service'));
        expect(exception.message, contains('GPS and fallback'));
      });

      test('has user-friendly message', () {
        // Arrange
        final exception = NoLocationServiceException();

        // Assert
        expect(
          exception.userMessage,
          contains('Unable to determine your location'),
        );
        expect(exception.userMessage, contains('enable location services'));
      });

      test('is instance of LocationException', () {
        // Arrange
        final exception = NoLocationServiceException();

        // Assert
        expect(exception, isA<LocationException>());
      });
    });

    // ========================================================================
    // TEST: InvalidLocationException
    // ========================================================================
    group('InvalidLocationException', () {
      test('stores invalid coordinates', () {
        // Arrange
        const double invalidLat = 100.0;
        const double invalidLng = 200.0;

        // Act
        final exception = InvalidLocationException(invalidLat, invalidLng);

        // Assert
        expect(exception.message, contains('100.0'));
        expect(exception.message, contains('200.0'));
      });

      test('includes coordinates in technical message', () {
        // Arrange
        const double lat = -45.5;
        const double lng = 179.9;

        // Act
        final exception = InvalidLocationException(lat, lng);

        // Assert
        expect(exception.message, contains('lat=-45.5'));
        expect(exception.message, contains('lng=179.9'));
      });

      test('has user-friendly message', () {
        // Arrange
        final exception = InvalidLocationException(100.0, 200.0);

        // Assert
        expect(exception.userMessage, contains('invalid location data'));
      });

      test('is instance of LocationException', () {
        // Arrange
        final exception = InvalidLocationException(50.0, 75.0);

        // Assert
        expect(exception, isA<LocationException>());
      });
    });

    // ========================================================================
    // TEST: LocationOutOfRangeException
    // ========================================================================
    group('LocationOutOfRangeException', () {
      test('stores distance and max distance', () {
        // Arrange
        const double distance = 150.0;
        const double maxDistance = 100.0;

        // Act
        final exception = LocationOutOfRangeException(
          distance: distance,
          maxDistance: maxDistance,
        );

        // Assert
        expect(exception.distance, equals(150.0));
        expect(exception.maxDistance, equals(100.0));
      });

      test('includes distances in technical message', () {
        // Arrange
        const double distance = 250.5;
        const double maxDistance = 100.0;

        // Act
        final exception = LocationOutOfRangeException(
          distance: distance,
          maxDistance: maxDistance,
        );

        // Assert
        expect(exception.message, contains('250.5'));
        expect(exception.message, contains('100.0'));
      });

      test('calculates excess distance in user message', () {
        // Arrange
        const double distance = 150.0;
        const double maxDistance = 100.0;

        // Act
        final exception = LocationOutOfRangeException(
          distance: distance,
          maxDistance: maxDistance,
        );

        // Assert
        // Excess distance = 150 - 100 = 50
        expect(exception.userMessage, contains('50 meters away'));
      });

      test('handles zero excess distance', () {
        // Arrange
        const double distance = 100.0;
        const double maxDistance = 100.0;

        // Act
        final exception = LocationOutOfRangeException(
          distance: distance,
          maxDistance: maxDistance,
        );

        // Assert
        expect(exception.userMessage, contains('0 meters away'));
      });

      test('is instance of LocationException', () {
        // Arrange
        final exception = LocationOutOfRangeException(
          distance: 200.0,
          maxDistance: 100.0,
        );

        // Assert
        expect(exception, isA<LocationException>());
      });
    });

    // ========================================================================
    // TEST: AlreadyLoggedInException
    // ========================================================================
    group('AlreadyLoggedInException', () {
      test('has appropriate technical message', () {
        // Arrange
        final exception = AlreadyLoggedInException();

        // Assert
        expect(
          exception.message,
          equals('Employee has already logged in today'),
        );
      });

      test('has user-friendly message', () {
        // Arrange
        final exception = AlreadyLoggedInException();

        // Assert
        expect(
          exception.userMessage,
          equals('You have already logged in today'),
        );
      });

      test('is instance of LocationException', () {
        // Arrange
        final exception = AlreadyLoggedInException();

        // Assert
        expect(exception, isA<LocationException>());
      });
    });

    // ========================================================================
    // TEST: LocationPermissionException
    // ========================================================================
    group('LocationPermissionException', () {
      test('indicates temporary denial when isPermanent is false', () {
        // Arrange
        final exception = LocationPermissionException(isPermanent: false);

        // Assert
        expect(exception.message, equals('Location permission denied'));
        expect(
          exception.userMessage,
          contains('Location permission is required'),
        );
      });

      test('indicates permanent denial when isPermanent is true', () {
        // Arrange
        final exception = LocationPermissionException(isPermanent: true);

        // Assert
        expect(exception.message, contains('permanently'));
        expect(exception.userMessage, contains('permanently'));
        expect(exception.userMessage, contains('app settings'));
      });

      test('is instance of LocationException', () {
        // Arrange
        final exception = LocationPermissionException(isPermanent: false);

        // Assert
        expect(exception, isA<LocationException>());
      });
    });

    // ========================================================================
    // TEST: GeolocationAPIException
    // ========================================================================
    group('GeolocationAPIException', () {
      test('includes HTTP status code in message', () {
        // Arrange
        const int statusCode = 403;

        // Act
        final exception = GeolocationAPIException(statusCode);

        // Assert
        expect(exception.message, contains('status: 403'));
      });

      test('handles different status codes', () {
        // Arrange & Act
        final exception404 = GeolocationAPIException(404);
        final exception500 = GeolocationAPIException(500);

        // Assert
        expect(exception404.message, contains('status: 404'));
        expect(exception500.message, contains('status: 500'));
      });

      test('has user-friendly message', () {
        // Arrange
        final exception = GeolocationAPIException(403);

        // Assert
        expect(exception.userMessage, contains('Unable to determine location'));
        expect(exception.userMessage, contains('enable GPS'));
      });

      test('is instance of LocationException', () {
        // Arrange
        final exception = GeolocationAPIException(500);

        // Assert
        expect(exception, isA<LocationException>());
      });
    });

    // ========================================================================
    // TEST: Exception Polymorphism
    // ========================================================================
    group('Exception Polymorphism', () {
      test('all exceptions can be caught as LocationException', () {
        // Arrange
        final exceptions = <LocationException>[
          GPSTimeoutException(),
          LocationAccuracyException(75.0),
          NoLocationServiceException(),
          InvalidLocationException(100.0, 200.0),
          LocationOutOfRangeException(distance: 150.0, maxDistance: 100.0),
          AlreadyLoggedInException(),
          LocationPermissionException(isPermanent: false),
          GeolocationAPIException(403),
        ];

        // Assert
        for (final exception in exceptions) {
          expect(exception, isA<LocationException>());
          expect(exception.message, isNotEmpty);
          expect(exception.userMessage, isNotEmpty);
        }
      });

      test('exception messages are never empty', () {
        // Arrange
        final exceptions = <LocationException>[
          GPSTimeoutException(),
          LocationAccuracyException(50.0),
          NoLocationServiceException(),
          InvalidLocationException(0.0, 0.0),
          LocationOutOfRangeException(distance: 200.0, maxDistance: 100.0),
          AlreadyLoggedInException(),
          LocationPermissionException(isPermanent: true),
          GeolocationAPIException(500),
        ];

        // Assert
        for (final exception in exceptions) {
          expect(
            exception.message.isNotEmpty,
            true,
            reason: '${exception.runtimeType} should have non-empty message',
          );
          expect(
            exception.userMessage.isNotEmpty,
            true,
            reason:
                '${exception.runtimeType} should have non-empty userMessage',
          );
        }
      });
    });
  });
}
