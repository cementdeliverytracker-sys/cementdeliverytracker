# Admin Feature Module Architecture

## Overview

The Admin feature module has been reorganized into a scalable, feature-based architecture. This document outlines the new structure, design principles, and how to extend it for future features.

## Directory Structure

```
lib/features/dashboard/presentation/pages/
├── admin/                           # Admin feature module
│   ├── index.dart                  # Main barrel file (export all admin features)
│   ├── pages/
│   │   ├── admin_dashboard_page.dart       # Navigation container (main entry point)
│   │   ├── dashboard_screen.dart           # Enterprise info display
│   │   ├── employees_list_page.dart        # Employee management
│   │   ├── pending_employee_requests_page.dart  # Approval workflow
│   │   ├── reports_screen.dart             # Reporting (placeholder)
│   │   └── index.dart                      # Pages barrel file
│   ├── services/
│   │   ├── admin_employee_service.dart     # Employee Firestore operations
│   │   └── index.dart                      # Services barrel file
│   └── widgets/
│       └── index.dart                      # Admin-specific widgets (currently empty)
├── admin_dashboard_page.dart        # Backward compatibility re-export
├── employee_dashboard_page.dart     # Employee feature
├── pending_approval_page.dart       # Pending approval feature
└── super_admin_dashboard_page.dart  # Super admin feature
```

## File Descriptions

### Pages (`/pages`)

#### `admin_dashboard_page.dart` - Navigation Container

- **Purpose**: Main entry point for the admin dashboard
- **Responsibilities**:
  - Navigation between dashboard screens (Indexed navigation)
  - Layout management (responsive design: drawer for large screens, bottom nav for mobile)
  - Theme application
- **Classes**: `AdminDashboardPage`, `_AdminDashboardPageState`
- **Screens**: Dashboard, Orders, Employees, Reports, Settings

#### `dashboard_screen.dart` - Enterprise Management

- **Purpose**: Display and manage enterprise information
- **Responsibilities**:
  - Show existing enterprise details (name, category, logo)
  - Provide enterprise setup form for new enterprises
  - Upload and store enterprise logos
  - Generate unique admin codes
- **Classes**: `DashboardScreen`, `_DashboardScreenState`
- **Key Methods**:
  - `_pickLogo()`: Image selection from gallery
  - `_saveEnterprise()`: Save enterprise info to Firestore
  - `_generateAdminCode()`: Create unique 8-char admin code

#### `employees_list_page.dart` - Employee Management

- **Purpose**: List and manage company employees
- **Components**:
  - `EmployeesScreen`: Overview of employee count (tap to view list)
  - `EmployeesListPage`: Detailed employee list with filters
- **Responsibilities**:
  - Display employee list with search/filter
  - Show employee details in modal bottom sheet
  - Navigate to pending requests approval
- **Classes**: `EmployeesScreen`, `_EmployeesScreenState`, `EmployeesListPage`, `_EmployeesListPageState`

#### `pending_employee_requests_page.dart` - Approval Workflow

- **Purpose**: Manage employee approval requests
- **Responsibilities**:
  - Display pending employee requests
  - Approve employees (assign employee ID)
  - Reject employee requests
  - Sort by request date
  - Show debug information for troubleshooting
- **Classes**: `PendingEmployeeRequestsPage`, `_PendingEmployeeRequestsPageState`
- **Key Methods**:
  - `_approveEmployee()`: Approve request and generate ID
  - `_rejectEmployee()`: Reject request and clean up data
  - `_showDebugInfo()`: Display all pending employees (development)

#### `reports_screen.dart` - Reporting

- **Purpose**: Placeholder for future reporting features
- **Current State**: Stub implementation
- **Future**: Analytics, employee reports, business metrics

### Services (`/services`)

#### `admin_employee_service.dart` - Employee Operations

- **Purpose**: Centralized employee Firestore operations
- **Scope**: Admin-specific employee management (not shared with employee users)
- **Class**: `AdminEmployeeService`
- **Methods**:
  - `generateUniqueEmployeeId()`: Create collision-resistant 6-digit ID
  - `approveEmployee(userId)`: Transition pending → approved, assign ID
  - `rejectEmployee(userId)`: Reject request, revert to temp employee
  - `getEmployeesStream(adminId)`: Real-time employee list
  - `getPendingEmployeesStream(adminId)`: Real-time pending requests
  - `getAllPendingEmployees()`: Get all pending (debug purposes)

**Design Pattern**: Service pattern for business logic separation
**Data Access**: Direct Firestore queries with where clauses
**Collections**: `users` collection with `userType` and `adminId` filters

### Widgets (`/widgets`)

- Currently empty (widgets shared from `dashboard_widgets.dart`)
- **Purpose**: Space for future admin-specific UI components
- **Examples**: Employee card, approval card, custom buttons, etc.

## Design Principles Applied

### 1. **Single Responsibility Principle (SRP)**

- Each file has one clear purpose
- Navigation logic isolated in `admin_dashboard_page.dart`
- Business logic isolated in `admin_employee_service.dart`

### 2. **Separation of Concerns**

- **Pages**: UI and user interaction
- **Services**: Data access and business logic
- **Widgets**: Reusable UI components

### 3. **Feature-Based Architecture**

- Admin functionality is isolated in its own module
- Easy to add new admin features (future: analytics, settings, etc.)
- Clear boundaries between admin/employee/super-admin features

### 4. **Dependency Inversion**

- Pages depend on services, not direct Firestore
- Easy to swap implementations (e.g., add caching, logging)

### 5. **DRY (Don't Repeat Yourself)**

- Reusable widgets: `DashboardCard`, `UserAvatar`, `LoadingState`, etc.
- Shared service methods for common operations
- Barrel files prevent repeated import statements

### 6. **Composition Over Inheritance**

- Screens composed of smaller components
- Stateful widgets manage only their state
- Flexible, testable design

## Import Patterns

### Barrel Files (Recommended)

```dart
// Clean, maintainable imports
import 'package:cementdeliverytracker/features/dashboard/presentation/pages/admin/index.dart';

// Access classes:
// AdminDashboardPage, DashboardScreen, EmployeesScreen, etc.
// AdminEmployeeService
```

### Direct Imports (For specific needs)

```dart
import 'package:cementdeliverytracker/features/dashboard/presentation/pages/admin/pages/employees_list_page.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/pages/admin/services/admin_employee_service.dart';
```

### Backward Compatibility

```dart
// Old import (still works via re-export)
import 'package:cementdeliverytracker/features/dashboard/presentation/pages/admin_dashboard_page.dart';
```

## Adding New Admin Features

### Step 1: Create Feature File

```dart
// lib/features/dashboard/presentation/pages/admin/pages/my_feature_page.dart
import 'package:cementdeliverytracker/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:flutter/material.dart';

class MyFeaturePage extends StatefulWidget {
  const MyFeaturePage({super.key});

  @override
  State<MyFeaturePage> createState() => _MyFeaturePageState();
}

class _MyFeaturePageState extends State<MyFeaturePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Feature')),
      body: const Center(child: Text('Feature content')),
    );
  }
}
```

### Step 2: Create Service (if needed)

```dart
// lib/features/dashboard/presentation/pages/admin/services/my_feature_service.dart
class MyFeatureService {
  // Business logic and Firestore operations
}
```

### Step 3: Update Barrel Files

```dart
// lib/features/dashboard/presentation/pages/admin/pages/index.dart
export 'admin_dashboard_page.dart';
export 'my_feature_page.dart';  // Add new export
// ... other exports

// lib/features/dashboard/presentation/pages/admin/services/index.dart
export 'admin_employee_service.dart';
export 'my_feature_service.dart';  // Add new export
```

### Step 4: Add to Navigation

```dart
// lib/features/dashboard/presentation/pages/admin/pages/admin_dashboard_page.dart
late final List<Widget> _screens = [
  const DashboardScreen(),
  const OrdersListPage(),
  const EmployeesScreen(),
  const ReportsScreen(),
  const MyFeaturePage(),  // Add new screen
  const SettingsScreen(),
];

// Update NavigationMenuConfig if adding permanent nav item
```

## State Management

- **Provider Pattern**: Used for authentication (`AuthNotifier`)
- **StreamBuilder**: Real-time Firestore data in pages
- **Stateful Widgets**: Local UI state (form inputs, animations, etc.)

## Testing Considerations

- **Services**: Unit test Firestore operations
- **Pages**: Widget tests for UI state and navigation
- **E2E**: Test complete flows (employee approval workflow)

## Migration Notes

### What Changed

1. Separated concerns: navigation, screens, services
2. Renamed `EmployeeService` → `AdminEmployeeService`
3. Moved employee service to admin module (`/admin/services/`)
4. Created barrel files for cleaner imports

### Backward Compatibility

- Old imports still work via re-export
- No breaking changes to public APIs
- Gradual migration possible

### Files to Update

- Any file importing `admin_dashboard_page.dart` from the pages directory (already updated in main.dart)
- Any file importing `EmployeeService` should use `AdminEmployeeService`

## Future Enhancements

### Potential Features

- Admin settings and preferences
- Employee reports and analytics
- Bulk employee operations
- Admin audit logs
- Permission/role management
- Notification center
- Document management

### Scalability

- Feature modules can easily add sub-pages
- Service layer supports caching/logging
- Barrel files simplify team coordination
- Clear patterns for new developers

## Common Patterns

### Fetching Data with Real-time Updates

```dart
StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
  stream: AdminEmployeeService().getEmployeesStream(adminId),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const LoadingState();
    }
    if (snapshot.hasError) {
      return ErrorState(message: 'Error: ${snapshot.error}');
    }
    final data = snapshot.data?.docs ?? [];
    // Display data
  },
)
```

### Showing Modal Details

```dart
showModalBottomSheet(
  context: context,
  backgroundColor: const Color(0xFF1E1E1E),
  builder: (ctx) => Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Details content
      ],
    ),
  ),
);
```

### Error Handling

```dart
try {
  await service.operation();
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Success')),
  );
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: $e')),
  );
}
```

---

**Document Version**: 1.0  
**Last Updated**: Current Session  
**Architecture**: Feature-based with Service/Page separation
