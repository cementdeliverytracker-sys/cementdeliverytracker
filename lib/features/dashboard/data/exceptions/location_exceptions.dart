/// Custom exceptions for location-based features
/// Provides user-friendly error messages and specific exception types

/// Base exception for location-related errors
abstract class LocationException implements Exception {
  /// Technical error message for logging
  final String message;

  /// User-friendly message to display in UI
  final String userMessage;

  LocationException({required this.message, required this.userMessage});

  @override
  String toString() => message;
}

/// Thrown when GPS takes too long to respond
class GPSTimeoutException extends LocationException {
  GPSTimeoutException()
    : super(
        message: 'GPS timeout after 10 seconds',
        userMessage:
            'GPS is taking too long. Make sure location services are enabled and you have a clear view of the sky.',
      );
}

/// Thrown when location accuracy is below acceptable threshold
class LocationAccuracyException extends LocationException {
  final double accuracy;

  LocationAccuracyException(this.accuracy)
    : super(
        message:
            'Location accuracy ($accuracy meters) exceeds acceptable threshold (50 meters)',
        userMessage:
            'Location accuracy is poor (±${accuracy.toStringAsFixed(0)} meters). '
            'Please move to an open area with clear sky view.',
      );
}

/// Thrown when no location service is available
class NoLocationServiceException extends LocationException {
  NoLocationServiceException()
    : super(
        message: 'No location service available (GPS and fallback both failed)',
        userMessage:
            'Unable to determine your location. Please enable location services and try again.',
      );
}

/// Thrown when location is outside valid coordinates
class InvalidLocationException extends LocationException {
  InvalidLocationException(double lat, double lng)
    : super(
        message: 'Invalid location coordinates: lat=$lat, lng=$lng',
        userMessage: 'Received invalid location data. Please try again.',
      );
}

/// Thrown when employee is too far from workplace
class LocationOutOfRangeException extends LocationException {
  final double distance;
  final double maxDistance;

  LocationOutOfRangeException({required this.distance, required this.maxDistance})
    : super(
        message:
            'Employee distance ($distance m) exceeds max allowed distance ($maxDistance m)',
        userMessage:
            'You are ${(distance - maxDistance).toStringAsFixed(0)} meters away from your workplace. '
            'Please move closer to stamp your login.',
      );
}

/// Thrown when employee already logged in today
class AlreadyLoggedInException extends LocationException {
  AlreadyLoggedInException()
    : super(
        message: 'Employee has already logged in today',
        userMessage: 'You have already logged in today',
      );
}

/// Thrown when location permissions are denied
class LocationPermissionException extends LocationException {
  LocationPermissionException({required bool isPermanent})
    : super(
        message:
            'Location permission denied${isPermanent ? ' permanently' : ''}',
        userMessage: isPermanent
            ? 'Location permission denied permanently. Please enable it in app settings.'
            : 'Location permission is required to stamp your login.',
      );
}

/// Thrown when Google Geolocation API returns an error
class GeolocationAPIException extends LocationException {
  GeolocationAPIException(int statusCode)
    : super(
        message: 'Google Geolocation API error (status: $statusCode)',
        userMessage:
            'Unable to determine location using network. Please enable GPS and try again.',
      );
}
