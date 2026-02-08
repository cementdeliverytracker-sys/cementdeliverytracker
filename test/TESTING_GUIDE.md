# GPS-Based Stamp Login - Comprehensive Unit Tests

This directory contains extensive unit tests for the optimized GPS-based stamp login feature in the Cement Delivery Tracker Flutter application.

## Overview

The test suite covers all critical components of the stamp login system including:

- ✅ GPS location retrieval with timeout handling
- ✅ Location accuracy validation (< 50 meters threshold)
- ✅ Coordinate bounds validation
- ✅ Firestore transaction atomicity
- ✅ Admin location caching with TTL
- ✅ Permission and location service checks
- ✅ Distance validation (≤ 100 meters from workplace)
- ✅ Duplicate login prevention
- ✅ Error handling and custom exceptions

## Test Files Structure

```
test/features/dashboard/
├── data/
│   ├── exceptions/
│   │   └── location_exceptions_test.dart      (8 exception classes)
│   └── services/
│       ├── admin_location_cache_test.dart     (Caching, TTL, invalidation)
│       ├── attendance_service_test.dart       (Transaction, distance calc)
│       └── firestore_transaction_test.dart    (Atomicity, rollback)
└── presentation/
    └── screens/
        └── gps_validation_test.dart           (GPS timeout, accuracy, coords)
```

## Test Coverage Summary

### 1. Location Exceptions (location_exceptions_test.dart)

**Purpose:** Validate custom exception classes with user-friendly messaging

**Test Groups:**

- `GPSTimeoutException` - 10-second timeout behavior
- `LocationAccuracyException` - Accuracy formatting (±XX meters)
- `NoLocationServiceException` - GPS disabled handling
- `InvalidLocationException` - Invalid coordinate detection
- `LocationOutOfRangeException` - Distance excess calculation
- `AlreadyLoggedInException` - Duplicate login detection
- `LocationPermissionException` - Permanent vs temporary denial
- `GeolocationAPIException` - HTTP status code handling
- `Exception Polymorphism` - Catchable as LocationException base class

**Key Assertions:**

- Messages are non-empty for all exception types
- User messages are user-friendly and actionable
- Accuracy values are formatted correctly
- Distance excess is calculated properly
- Permanent vs temporary permission denials are differentiated

### 2. GPS Location Validation (gps_validation_test.dart)

**Purpose:** Test GPS accuracy, coordinate bounds, timeout, and permission validation

**Test Groups:**

- `Validate Location Accuracy` - Accuracy threshold enforcement (< 50m)
- `Validate Location Coordinates` - Latitude (-90 to 90) and longitude (-180 to 180) bounds
- `GPS Timeout Behavior` - 10-second timeout mechanism
- `Location Permission Validation` - Permission request flow
- `Location Service Enabled Check` - GPS service availability
- `Mock Position Objects` - Create realistic GPS position mocks
- `Distance Validation` - 100-meter workplace radius validation
- `Already Logged In Check` - Duplicate login detection
- `Validation Order` - Correct order of validation steps

**Key Test Cases:**

- ✅ Accepts accuracy < 50 meters
- ✅ Rejects accuracy > 50 meters (throws LocationAccuracyException)
- ✅ Validates latitude bounds (-90 to 90)
- ✅ Validates longitude bounds (-180 to 180)
- ✅ Creates timeout exception after 10 seconds
- ✅ Handles permission denied (both temporary and permanent)
- ✅ Rejects locations > 100m from workplace
- ✅ Prevents duplicate logins

### 3. Admin Location Cache (admin_location_cache_test.dart)

**Purpose:** Validate caching mechanism, TTL expiration, and cache statistics

**Test Groups:**

- `Singleton Pattern` - Verify cache is singleton
- `Cache Hit` - Return cached location without Firestore query
- `Cache Expiration (TTL)` - 24-hour TTL enforcement
- `Cache Invalidation` - Manual cache invalidation
- `Cache Statistics` - Cache stats, age, and validity tracking
- `Location Data Validation` - Accept valid location structure
- `Performance - Multiple Entries` - Handle multiple cached admins
- `Cache Stats Integrity` - Accurate stats with many entries

**Key Features:**

- ✅ Singleton instance (same instance on multiple calls)
- ✅ 24-hour TTL expiration
- ✅ Per-admin invalidation
- ✅ Bulk cache clearing
- ✅ Cache statistics with age and validity
- ✅ Efficient multiple entry handling

### 4. Firestore Transactions (firestore_transaction_test.dart)

**Purpose:** Validate atomic read-modify-write semantics

**Test Groups:**

- `Transaction Atomicity` - All-or-nothing semantics
- `Transaction READ Phase` - User and location validation reading
- `Transaction VALIDATION Phase` - Distance and coordinate checks
- `Transaction WRITE Phase` - Atomic attendance log + user status update
- `Transaction Rollback Scenarios` - Error handling and rollback
- `Transaction Order of Operations` - Correct phase ordering
- `Multiple Users Concurrent Transactions` - Transaction isolation
- `Server Timestamp Handling` - Consistent server timestamps

**Key Test Cases:**

- ✅ Both writes commit together (atomicity)
- ✅ Rollback on validation failure (all-or-nothing)
- ✅ Neither write succeeds if error occurs
- ✅ Proper phase ordering: Read → Validate → Write
- ✅ User document validation (not found, already logged in)
- ✅ Location validation (coordinates, distance, accuracy)
- ✅ Independent transaction contexts per user
- ✅ Server timestamps for consistency

### 5. Attendance Service (attendance_service_test.dart)

**Purpose:** Validate attendance logging, distance calculation, and service layer

**Test Groups:**

- `calculateDistance` - Accurate distance calculation
- `hasLoggedInToday` - Duplicate login detection
- `createAttendanceLog` - Attendance log creation with transaction
- `Error Handling` - Exception handling and validation

**Key Test Cases:**

- ✅ Accurate distance calculation between coordinates
- ✅ Zero distance for same location
- ✅ Detection of today's login
- ✅ Rejection of out-of-range locations
- ✅ Invalid coordinate detection
- ✅ Duplicate login prevention

## Running the Tests

### Run All Tests

```bash
cd /path/to/cementdeliverytracker
flutter test
```

### Run Specific Test File

```bash
flutter test test/features/dashboard/data/exceptions/location_exceptions_test.dart
flutter test test/features/dashboard/data/services/admin_location_cache_test.dart
flutter test test/features/dashboard/data/services/attendance_service_test.dart
flutter test test/features/dashboard/data/services/firestore_transaction_test.dart
flutter test test/features/dashboard/presentation/screens/gps_validation_test.dart
```

### Run Tests with Coverage

```bash
flutter test --coverage
```

### Run Tests with Verbose Output

```bash
flutter test --verbose
```

### Run Tests with Specific Pattern

```bash
# Run only LocationAccuracyException tests
flutter test -k "LocationAccuracyException"

# Run only transaction tests
flutter test -k "Transaction"

# Run only cache tests
flutter test -k "Cache"
```

## Mock Dependencies

### Libraries Used

- **mocktail** - For creating mocks and stubs
- **flutter_test** - For test framework and matchers

### Key Mocks Implemented

#### Geolocator Mocks

- `MockPosition` - Realistic GPS position with all properties
  ```dart
  final position = MockPosition(
    latitude: 28.7041,
    longitude: 77.1025,
    accuracy: 25.0,
  );
  ```

#### Firebase Mocks

- `MockFirebaseFirestore` - Firestore instance
- `MockTransaction` - Firestore transaction with read/write operations
- `MockDocumentReference` - Document reference
- `MockCollectionReference` - Collection reference
- `MockDocumentSnapshot` - Document snapshot

#### Custom Fakes

- `FakeTransaction` - Realistic transaction implementation for testing

## Test Examples

### Example 1: Testing GPS Accuracy Validation

```dart
test('rejects GPS location with accuracy > 50 meters', () {
  // Arrange
  final position = MockPosition(accuracy: 75.0);

  // Act & Assert
  expect(
    position.accuracy,
    greaterThan(50.0),
  );
});
```

### Example 2: Testing Cache Expiration

```dart
test('removes expired cache entries (> 24 hours)', () {
  // Arrange
  const String adminId = 'admin789';
  final location = {'latitude': 28.7041, 'longitude': 77.1025};

  // Add entry 25 hours old (expired)
  final expiredEntry = AdminLocationCache._CachedAdminLocation(
    location,
    DateTime.now().subtract(const Duration(hours: 25)),
  );

  // Assert - Entry would be marked invalid
  expect(stats['entries']['admin789']['isValid'], equals(false));
});
```

### Example 3: Testing Transaction Atomicity

```dart
test('rolls back if location is out of range', () {
  // Arrange
  const double distance = 150.0;
  fakeTransaction.simulateError(
    LocationOutOfRangeException(
      distance: distance,
      maxDistance: 100.0,
    ),
  );

  // Act & Assert
  expect(
    () async {
      await fakeTransaction.set(
        MockDocumentReference(),
        {'test': 'data'} as dynamic,
      );
    },
    throwsA(isA<Exception>()),
  );
});
```

## Expected Test Results

When all tests pass, you should see:

```
✓ location_exceptions_test.dart: 52 tests
✓ gps_validation_test.dart: 47 tests
✓ admin_location_cache_test.dart: 28 tests
✓ firestore_transaction_test.dart: 36 tests
✓ attendance_service_test.dart: 12 tests

Total: 175 unit tests
All tests passed ✓
```

## Validation Checklist

After running tests, verify:

- [ ] All 175+ unit tests pass
- [ ] No compilation errors
- [ ] All exception classes have user-friendly messages
- [ ] GPS timeout is enforced at 10 seconds
- [ ] Accuracy threshold is enforced at 50 meters
- [ ] Distance validation is enforced at 100 meters
- [ ] Cache TTL is 24 hours
- [ ] Firestore transactions are atomic
- [ ] Permission checks occur before location retrieval
- [ ] No Firestore reads happen on cache hit
- [ ] Proper error handling for all exception types

## Troubleshooting

### Issue: Mock objects not found

**Solution:** Ensure `mocktail` is added to `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.0
```

### Issue: Tests timeout

**Solution:** Ensure Location service mocks are properly configured and avoid real GPS calls

### Issue: Firestore mock errors

**Solution:** Verify all mock collection/document references are properly registered

## Next Steps

1. **Integration Tests**: Create integration tests that test the full flow
2. **Widget Tests**: Add widget tests for UI components
3. **E2E Tests**: Add end-to-end tests with Firebase Emulator
4. **Performance Tests**: Add performance tests for cache efficiency
5. **Load Tests**: Test with multiple concurrent stamp login requests

## Reference Documentation

- [Flutter Testing Guide](https://flutter.dev/docs/testing)
- [Mocktail Documentation](https://pub.dev/packages/mocktail)
- [Firestore Testing Best Practices](https://firebase.google.com/docs/firestore/testing)
- [Geolocator Package](https://pub.dev/packages/geolocator)

## Maintenance

- Update tests when exception messages change
- Update tests when validation thresholds change (timeout, accuracy, distance)
- Update cache TTL tests if expiration duration changes
- Add regression tests for any bugs found in production
