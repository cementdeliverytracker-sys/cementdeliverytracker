# Distributor Visit Tracking Feature

Complete implementation of employee distributor visit tracking with GPS-based check-in/out, task logging, and offline support.

## Features

✅ **Distributor Management**

- View list of active distributors
- Add new distributors with location details
- Search distributors by name or contact
- Find nearby distributors based on GPS coordinates
- Update distributor information

✅ **Visit Tracking**

- GPS-based check-in with location accuracy
- Task logging during visits (collect money, take order, etc.)
- GPS-based check-out with location tracking
- One active visit per employee at a time
- Visit duration tracking

✅ **Task Management**

- Multiple task types: Collect Money, Take Order, Other
- Task descriptions and metadata (e.g., amount collected)
- Task timestamps for audit trail
- Flexible metadata for task-specific data

✅ **History & Reporting**

- Daily visit history with all details
- Visit duration, task counts, and status
- GPS accuracy for quality assurance
- Visit statistics (total visits, completed visits, active visits, total tasks)
- Task breakdown by type

## Architecture

### Data Layer

**Models** (`data/models/`)

- `distributor_model.dart`: Distributor entity with location
- `visit_model.dart`: Visit, VisitTask, TaskType enum
- `visit_history_model.dart`: Visit history display model

**Services** (`data/services/`)

- `distributor_service.dart`: CRUD operations with local caching
- `visit_service.dart`: Visit management with Firestore integration

**Repository** (`data/repositories/`)

- `distributor_repository.dart`: Business logic abstraction layer

### Presentation Layer

**Screens** (`presentation/screens/`)

- `employee_visit_screen.dart`: Main screen with tabs for current visit and history

**Widgets** (`presentation/widgets/`)

- `visit_status_widget.dart`: Display current visit status and details
- `distributor_selector_widget.dart`: Distributor selection with search
- `task_logging_widget.dart`: Task type selection and logging dialog
- `visit_history_widget.dart`: Daily visit history display

## Data Models

### Distributor

```dart
Distributor(
  id: String,
  name: String,
  contact: String,
  address: String,
  latitude: double?,
  longitude: double?,
  adminId: String,
  createdAt: DateTime,
  updatedAt: DateTime,
  isActive: bool,
)
```

### Visit

```dart
Visit(
  id: String,
  employeeId: String,
  distributorId: String,
  distributorName: String,
  checkInTime: DateTime,
  checkOutTime: DateTime?,
  checkInLat: double,
  checkInLng: double,
  checkInAccuracy: double,
  checkOutLat: double?,
  checkOutLng: double?,
  checkOutAccuracy: double?,
  tasks: List<VisitTask>,
  isCompleted: bool,
  createdAt: DateTime,
  updatedAt: DateTime,
)
```

### VisitTask

```dart
VisitTask(
  id: String,
  visitId: String,
  type: TaskType, // collectMoney, takeOrder, other
  description: String,
  timestamp: DateTime,
  metadata: Map<String, dynamic>, // Amount, order details, etc.
)
```

## Firestore Database Structure

```
firestore/
├── distributors/
│   ├── {id}
│   │   ├── name: String
│   │   ├── contact: String
│   │   ├── address: String
│   │   ├── location: { latitude, longitude }
│   │   ├── adminId: String
│   │   ├── createdAt: Timestamp
│   │   ├── updatedAt: Timestamp
│   │   └── isActive: Boolean
│
└── visits/
    ├── {id}
    │   ├── employeeId: String
    │   ├── distributorId: String
    │   ├── distributorName: String
    │   ├── checkInTime: Timestamp
    │   ├── checkOutTime: Timestamp (optional)
    │   ├── checkInLocation: { latitude, longitude, accuracy }
    │   ├── checkOutLocation: { latitude, longitude, accuracy } (optional)
    │   ├── tasks: Array of TaskObjects
    │   ├── isCompleted: Boolean
    │   ├── createdAt: Timestamp
    │   └── updatedAt: Timestamp
```

## Services & Methods

### DistributorService

```dart
// Get all distributors
Future<List<Distributor>> getDistributors({bool forceRefresh = false})

// Get distributor by ID
Future<Distributor?> getDistributorById(String id)

// Add new distributor
Future<String> addDistributor({...})

// Update distributor
Future<void> updateDistributor(String id, {...})

// Delete distributor (soft delete)
Future<void> deleteDistributor(String id)

// Search distributors
List<Distributor> searchDistributors(String query)

// Get nearby distributors
List<Distributor> getNearbyDistributors(double lat, double lng, double radiusKm)
```

### VisitService

```dart
// Get active visit
Future<Visit?> getActiveVisit(String employeeId)

// Get today's visits
Future<List<Visit>> getTodayVisits(String employeeId)

// Check-in (start visit)
Future<String> checkIn({
  required String employeeId,
  required String distributorId,
  required String distributorName,
  required double latitude,
  required double longitude,
  required double accuracy,
})

// Add task to active visit
Future<void> addTask({
  required String visitId,
  required TaskType taskType,
  required String description,
  Map<String, dynamic>? metadata,
})

// Check-out (complete visit)
Future<void> checkOut({
  required String visitId,
  required double latitude,
  required double longitude,
  required double accuracy,
})

// Get visit by ID
Future<Visit?> getVisitById(String id)

// Get distributor visits
Future<List<Visit>> getDistributorVisits(
  String distributorId, {
  DateTime? startDate,
  DateTime? endDate,
})

// Get visit statistics
Future<Map<String, dynamic>> getVisitStats(String employeeId)
```

## Integration Guide

### 1. Add to main.dart

```dart
import 'features/distributor/feature_providers.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ...DistributorFeatureProviders.getProviders(),
        // Other providers...
      ],
      child: const MyApp(),
    ),
  );
}
```

### 2. Navigate to Employee Visit Screen

```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => const EmployeeVisitScreen(
      employeeId: 'employee_id_from_auth',
      employeeName: 'Employee Name',
    ),
  ),
);
```

### 3. Required Permissions (AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

### 4. Required Permissions (iOS - Info.plist)

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs your location to track distributor visits</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs your location to track distributor visits</string>
```

## Dependencies

Required packages (add to pubspec.yaml):

```yaml
dependencies:
  cloud_firestore: ^latest
  provider: ^latest
  geolocator: ^latest
  flutter:
    sdk: flutter
```

## Key Features Implemented

### GPS Tracking

- Check-in and check-out with GPS coordinates
- Location accuracy tracking for quality assurance
- Automatic location permission handling

### Task Management

- Flexible task types (Collect Money, Take Order, Other)
- Task descriptions and metadata
- Timestamp tracking for each task

### Offline Support Ready

- Models designed for local storage serialization
- Firestore integration for cloud sync
- Cache management for better performance

### Real-time Updates

- Active visit tracking
- One active visit constraint per employee
- Automatic status updates

## Error Handling

All services include:

- Try-catch error handling
- User-friendly error messages
- Error state management via ChangeNotifier
- Graceful fallbacks

## Caching Strategy

- **Distributor Cache**: In-memory cache with force refresh option
- **Visit Cache**: Time-based caching of visit data
- **Active Visit Cache**: Quick access to current visit

## Testing Scenarios

1. **Check-in**: Employee selects distributor → app captures GPS → creates visit record
2. **Task Logging**: During active visit → employee logs task (money/order) → task added with timestamp
3. **Check-out**: Employee checks out → app captures GPS → visit marked complete
4. **History**: View daily visits with all tasks, duration, and GPS accuracy

## Future Enhancements

- [ ] Offline sync when online
- [ ] SQLite/Hive local storage
- [ ] Geofencing for automatic check-in
- [ ] Photo/signature capture
- [ ] Real-time route optimization
- [ ] Manager dashboard with distributor analytics
- [ ] Push notifications for visit reminders

## Notes

- Firestore Indexes: Auto-created by Firestore for `getTodayVisits` and `getActiveVisit` queries
- Location accuracy: Values in meters, typically 5-30m with modern devices
- Visit transactions: Future enhancement for atomic check-in/out operations
- Admin ID: Currently hardcoded; integrate with auth provider in production
