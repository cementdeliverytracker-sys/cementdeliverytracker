# Test Setup and Configuration Guide

This guide provides step-by-step instructions for setting up and running the comprehensive GPS stamp login tests.

## Prerequisites

- Flutter SDK 3.0 or higher
- Dart SDK 3.0 or higher
- Android SDK (for Android testing)
- Xcode (for iOS testing)

## Step 1: Update pubspec.yaml

Ensure your `pubspec.yaml` includes the required dev dependencies for testing:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter

  # Mocking library for unit tests
  mocktail: ^1.0.0

  # Code coverage reporting
  coverage: ^7.0.0
```

### Installing Dependencies

```bash
flutter pub get
```

## Step 2: Directory Structure Setup

Ensure the test directory structure exists:

```
test/
├── features/
│   └── dashboard/
│       ├── data/
│       │   ├── exceptions/
│       │   │   └── location_exceptions_test.dart
│       │   └── services/
│       │       ├── admin_location_cache_test.dart
│       │       ├── attendance_service_test.dart
│       │       └── firestore_transaction_test.dart
│       └── presentation/
│           └── screens/
│               └── gps_validation_test.dart
├── TESTING_GUIDE.md
└── TEST_SETUP.md (this file)
```

### Create Directories

```bash
mkdir -p test/features/dashboard/data/exceptions
mkdir -p test/features/dashboard/data/services
mkdir -p test/features/dashboard/presentation/screens
```

## Step 3: Run Tests

### Run All Tests

```bash
flutter test
```

### Run Specific Test File

```bash
# Exception tests
flutter test test/features/dashboard/data/exceptions/location_exceptions_test.dart

# GPS validation tests
flutter test test/features/dashboard/presentation/screens/gps_validation_test.dart

# Cache tests
flutter test test/features/dashboard/data/services/admin_location_cache_test.dart

# Firestore transaction tests
flutter test test/features/dashboard/data/services/firestore_transaction_test.dart

# Attendance service tests
flutter test test/features/dashboard/data/services/attendance_service_test.dart
```

### Run Tests by Pattern

```bash
# Run all exception-related tests
flutter test -k "Exception"

# Run all cache-related tests
flutter test -k "Cache"

# Run all timeout-related tests
flutter test -k "Timeout"

# Run all distance validation tests
flutter test -k "Distance"
```

## Step 4: Generate Code Coverage Report

### Generate Coverage Data

```bash
flutter test --coverage
```

This generates coverage data in `coverage/lcov.info`.

### View Coverage Report

#### On macOS/Linux

```bash
# Install lcov (if not already installed)
brew install lcov  # macOS
# or
sudo apt-get install lcov  # Linux

# Generate HTML coverage report
genhtml coverage/lcov.info -o coverage/html

# Open in browser
open coverage/html/index.html
```

#### Generate Coverage Summary

```bash
flutter test --coverage | grep -E "^(✓|✗|=)" | tail -20
```

## Step 5: Continuous Integration (CI) Setup

### GitHub Actions Example

Create `.github/workflows/test.yml`:

```yaml
name: Unit Tests

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: "3.10.0"

      - run: flutter pub get

      - run: flutter test

      - run: flutter test --coverage

      - uses: codecov/codecov-action@v3
        with:
          files: ./coverage/lcov.info
```

## Test Execution Details

### Test Categories

#### 1. Unit Tests (No Firebase)

- Exception validation (location_exceptions_test.dart)
- GPS validation logic (gps_validation_test.dart)
- Cache logic (admin_location_cache_test.dart)

**Run Time:** ~2-3 seconds

```bash
flutter test test/features/dashboard/data/exceptions/
flutter test test/features/dashboard/presentation/screens/gps_validation_test.dart
```

#### 2. Service Layer Tests (Mocked Firebase)

- Distance calculations
- Transaction logic
- Cache-Firestore interaction

**Run Time:** ~3-5 seconds

```bash
flutter test test/features/dashboard/data/services/
```

#### 3. Full Integration Tests

- End-to-end stamp login flow
- Multiple users concurrent operations
- Error recovery scenarios

**Run Time:** ~5-10 seconds

### Expected Output

```
test/features/dashboard/data/exceptions/location_exceptions_test.dart
✓ LocationException Tests (52 tests)
  ✓ GPSTimeoutException (4 tests)
  ✓ LocationAccuracyException (5 tests)
  ✓ NoLocationServiceException (3 tests)
  ✓ InvalidLocationException (4 tests)
  ✓ LocationOutOfRangeException (5 tests)
  ✓ AlreadyLoggedInException (3 tests)
  ✓ LocationPermissionException (3 tests)
  ✓ GeolocationAPIException (4 tests)
  ✓ Exception Polymorphism (2 tests)

test/features/dashboard/presentation/screens/gps_validation_test.dart
✓ GPS Location Validation Tests (47 tests)
  ✓ Validate Location Accuracy (6 tests)
  ✓ Validate Location Coordinates (8 tests)
  ✓ GPS Timeout Behavior (4 tests)
  ✓ Location Permission Validation (3 tests)
  ✓ Location Service Enabled Check (3 tests)
  ✓ Mock Position Objects (5 tests)
  ✓ Distance Validation (5 tests)
  ✓ Already Logged In Check (3 tests)
  ✓ Exception Chain Handling (2 tests)
  ✓ Validation Order (3 tests)

test/features/dashboard/data/services/admin_location_cache_test.dart
✓ AdminLocationCache Tests (28 tests)
  ✓ Singleton Pattern (2 tests)
  ✓ Cache Hit (2 tests)
  ✓ Cache Expiration (TTL) (3 tests)
  ✓ Cache Invalidation (3 tests)
  ✓ Cache Statistics (3 tests)
  ✓ Location Data Validation (2 tests)
  ✓ Performance - Multiple Entries (2 tests)

test/features/dashboard/data/services/firestore_transaction_test.dart
✓ Firestore Transaction Tests (36 tests)
  ✓ Transaction Atomicity (3 tests)
  ✓ Transaction READ Phase (4 tests)
  ✓ Transaction VALIDATION Phase (5 tests)
  ✓ Transaction WRITE Phase (4 tests)
  ✓ Transaction Rollback Scenarios (5 tests)
  ✓ Transaction Order of Operations (3 tests)
  ✓ Multiple Users Concurrent Transactions (2 tests)
  ✓ Server Timestamp Handling (3 tests)

test/features/dashboard/data/services/attendance_service_test.dart
✓ AttendanceService Tests (12 tests)
  ✓ calculateDistance (2 tests)
  ✓ hasLoggedInToday (1 test)
  ✓ createAttendanceLog (4 tests)
  ✓ getTodayAttendance (1 test)

═══════════════════════════════════════════════════
Total: 175 tests passed in 8.5 seconds
═══════════════════════════════════════════════════
```

## Debugging Tests

### Run Tests with Verbose Output

```bash
flutter test --verbose
```

### Run Single Test

```bash
flutter test test/features/dashboard/data/exceptions/location_exceptions_test.dart -k "GPSTimeoutException"
```

### Debug Mode (Pause on Failure)

```bash
flutter test --pause-on-test-failure
```

### Filter Output

```bash
# Show only failed tests
flutter test | grep -A5 "✗"

# Show only passed tests
flutter test | grep "✓"
```

## Troubleshooting

### Issue: "Package not found" errors

**Solution:** Run pub get and clean

```bash
flutter pub get
flutter clean
flutter pub get
```

### Issue: Mock-related compilation errors

**Solution:** Ensure mocktail is properly imported

```dart
import 'package:mocktail/mocktail.dart';
```

### Issue: Test hangs or times out

**Solution:**

- Check for infinite loops in test code
- Ensure async operations complete
- Use appropriate timeouts

```dart
test('async test', () async {
  final result = await Future.delayed(Duration(seconds: 1), () => 'done');
  expect(result, equals('done'));
}, timeout: Timeout(Duration(seconds: 5)));
```

### Issue: Firebase-related test failures

**Solution:** Ensure FirebaseFirestore is properly mocked

```dart
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

void setUp() {
  mockFirestore = MockFirebaseFirestore();
  // Configure mock returns
}
```

## Best Practices

### 1. Test Isolation

Each test should be independent and not rely on other tests:

```dart
setUp(() {
  // Reset mocks before each test
  reset(mockFirestore);
  AdminLocationCache().clearAllCache();
});
```

### 2. Clear Test Names

Use descriptive test names that explain what is being tested:

```dart
test('throws LocationAccuracyException when accuracy > 50 meters', () {
  // ...
});
```

### 3. Arrange-Act-Assert Pattern

Follow AAA pattern for clear test structure:

```dart
test('example', () {
  // Arrange - Set up test data
  final position = MockPosition(accuracy: 75.0);

  // Act - Execute the code being tested
  final isInvalid = position.accuracy > 50.0;

  // Assert - Verify the results
  expect(isInvalid, equals(true));
});
```

### 4. Use Meaningful Assertions

```dart
// Good
expect(exception.userMessage, contains('open area'));

// Avoid
expect(exception.userMessage.isNotEmpty, equals(true));
```

### 5. Test Edge Cases

```dart
test('validates corner case latitude = 90', () {
  expect(90.0, inInclusiveRange(-90, 90));
});

test('validates corner case latitude = -90', () {
  expect(-90.0, inInclusiveRange(-90, 90));
});
```

## Performance Benchmarks

Expected test execution times:

| Test File                       | Count   | Time      |
| ------------------------------- | ------- | --------- |
| location_exceptions_test.dart   | 52      | 0.8s      |
| gps_validation_test.dart        | 47      | 1.2s      |
| admin_location_cache_test.dart  | 28      | 0.9s      |
| firestore_transaction_test.dart | 36      | 1.8s      |
| attendance_service_test.dart    | 12      | 0.6s      |
| **Total**                       | **175** | **~5-8s** |

## Resources

- [Flutter Testing Documentation](https://flutter.dev/docs/testing)
- [Dart Testing Guide](https://dart.dev/guides/testing)
- [Mocktail Package](https://pub.dev/packages/mocktail)
- [Firebase Testing Best Practices](https://firebase.google.com/docs/firestore/testing)

## Next Steps

After tests pass:

1. Add integration tests with Firebase Emulator
2. Add widget tests for UI components
3. Set up CI/CD pipeline
4. Monitor test coverage metrics
5. Add performance benchmarks
