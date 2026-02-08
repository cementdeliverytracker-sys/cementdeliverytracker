# Quick Reference: Distributor Visit Feature

## 📁 Project Structure

```
lib/features/distributor/
├── data/
│   ├── models/
│   │   ├── distributor_model.dart       # Distributor entity
│   │   ├── visit_model.dart              # Visit + VisitTask + TaskType
│   │   └── visit_history_model.dart      # History display model
│   ├── services/
│   │   ├── distributor_service.dart      # CRUD + caching
│   │   └── visit_service.dart            # Check-in/out + tasks
│   └── repositories/
│       └── distributor_repository.dart   # Business logic layer
├── presentation/
│   ├── screens/
│   │   └── employee_visit_screen.dart    # Main screen
│   └── widgets/
│       ├── visit_status_widget.dart      # Status display
│       ├── distributor_selector_widget.dart  # Distributor selection
│       ├── task_logging_widget.dart      # Task management
│       └── visit_history_widget.dart     # History display
└── feature_providers.dart                 # Provider setup
```

## 🚀 Quick Start

### 1. Add to main.dart

```dart
import 'features/distributor/feature_providers.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ...DistributorFeatureProviders.getProviders(),
      ],
      child: const MyApp(),
    ),
  );
}
```

### 2. Navigate to Screen

```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => const EmployeeVisitScreen(
      employeeId: 'emp_001',
      employeeName: 'John Doe',
    ),
  ),
);
```

## 📊 Main Classes

### Models

```dart
Distributor(id, name, contact, address, location...)
Visit(id, employeeId, distributorId, checkInTime, checkOutTime, tasks...)
VisitTask(id, visitId, type, description, timestamp, metadata)
TaskType (collectMoney, takeOrder, other)
```

### Services

```dart
DistributorService: getDistributors(), addDistributor(), searchDistributors()...
VisitService: checkIn(), checkOut(), addTask(), getTodayVisits()...
```

### UI Components

```dart
EmployeeVisitScreen: Main tab-based screen
VisitStatusWidget: Shows current visit details
DistributorSelectorWidget: Select/search distributors
TaskLoggingWidget: Log tasks with details
VisitHistoryWidget: Daily visit history
```

## 🔑 Key Methods

### Check-in

```dart
final visitId = await repository.checkIn(
  employeeId: 'emp_001',
  distributorId: 'dist_001',
  distributorName: 'ABC Distributor',
  latitude: 28.6139,
  longitude: 77.2090,
  accuracy: 8.5,
);
```

### Add Task

```dart
await repository.addTask(
  visitId: visitId,
  taskType: TaskType.collectMoney,
  description: 'Collected monthly payment',
  metadata: {'amount': 5000},
);
```

### Check-out

```dart
await repository.checkOut(
  visitId: visitId,
  latitude: 28.6150,
  longitude: 77.2085,
  accuracy: 6.2,
);
```

### Get Active Visit

```dart
final activeVisit = await repository.getActiveVisit('emp_001');
```

### Get Today's Visits

```dart
final visits = await repository.getTodayVisits('emp_001');
```

## 🎯 TaskType Values

- `TaskType.collectMoney` - For payment collections
- `TaskType.takeOrder` - For order placement
- `TaskType.other` - For miscellaneous tasks

## 📱 UI Features

**Current Visit Tab**

- Shows active visit status
- Distributor selection if no active visit
- Task logging options
- Check-out button

**History Tab**

- Daily visit cards
- Task breakdown
- Duration tracking
- GPS accuracy info

## 🔌 Required Permissions

**Android (AndroidManifest.xml)**

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

**iOS (Info.plist)**

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Permission needed for visit tracking</string>
```

## 📦 Dependencies

```yaml
cloud_firestore: ^4.0.0
provider: ^6.0.0
geolocator: ^9.0.0
```

## 💾 Firestore Structure

- `distributors/` - Distributor records
- `visits/` - Visit records with nested tasks and locations

## 🧪 Test Scenarios

1. **User Opens Screen** → Loads active visit status
2. **User Selects Distributor** → Check-in button enabled
3. **User Taps Check-in** → Captures GPS → Creates visit
4. **User Logs Tasks** → Task added with metadata
5. **User Checks Out** → Captures GPS → Visit completed
6. **View History** → Shows all tasks and duration

## ⚙️ Customization

### Add Custom Task Type

Edit `TaskType` enum in visit_model.dart:

```dart
enum TaskType {
  collectMoney('Collect Money'),
  takeOrder('Take Order'),
  customType('Custom Type'),
  other('Other');

  final String displayName;
  const TaskType(this.displayName);
}
```

### Change Colors

Edit widgets/visit_status_widget.dart and other widgets to customize color scheme

### Modify Visit Fields

Add fields to Visit class in visit_model.dart and update toFirestore/fromFirestore

## 📞 Support

For issues or customization:

1. Check DISTRIBUTOR_VISIT_FEATURE.md for detailed docs
2. Review IMPLEMENTATION_SUMMARY_DISTRIBUTOR_VISIT.md for architecture
3. Check widget code comments for implementation details

---

**Everything is ready to use!** 🎉
