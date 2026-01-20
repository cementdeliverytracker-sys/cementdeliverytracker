# Refactored Code Usage Examples

## Dashboard Widgets Usage

### 1. DashboardCard

Replaces manual Card + InkWell + Padding combinations.

**Before:**

```dart
Card(
  color: const Color(0xFF1E1E1E),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
  ),
  elevation: AppConstants.defaultElevation,
  child: InkWell(
    borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
    onTap: () => Navigator.push(...),
    child: Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Row(/* content */),
    ),
  ),
)
```

**After:**

```dart
DashboardCard(
  onTap: () => Navigator.push(...),
  child: Row(/* content */),
)
```

**With custom styling:**

```dart
DashboardCard(
  backgroundColor: Colors.red,
  borderRadius: 20,
  onTap: () {},
  child: Text('Custom Card'),
)
```

---

### 2. UserAvatar

Encapsulates user initials display in circular avatar.

**Before:**

```dart
CircleAvatar(
  backgroundColor: const Color(0xFFFF6F00),
  child: Text(
    name.isNotEmpty ? name[0].toUpperCase() : '?',
    style: const TextStyle(color: Colors.white),
  ),
)
```

**After:**

```dart
UserAvatar(name: name)
```

**With options:**

```dart
UserAvatar(
  name: 'John Doe',
  radius: 32,
  backgroundColor: Colors.blue,
  textColor: Colors.white,
)
```

---

### 3. State Widgets (LoadingState, ErrorState, EmptyState)

Consistent UI for async states in StreamBuilder.

**Before:**

```dart
if (snapshot.connectionState == ConnectionState.waiting) {
  return const Center(child: CircularProgressIndicator());
}

if (snapshot.hasError) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.red),
        const SizedBox(height: 16),
        Text('Error: ${snapshot.error}'),
      ],
    ),
  );
}

if (employees.isEmpty) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.people_outline, size: 64),
        SizedBox(height: 12),
        Text('No employees yet'),
      ],
    ),
  );
}
```

**After:**

```dart
if (snapshot.connectionState == ConnectionState.waiting) {
  return const LoadingState();
}

if (snapshot.hasError) {
  return ErrorState(message: 'Failed to load: ${snapshot.error}');
}

if (employees.isEmpty) {
  return const EmptyState(
    message: 'No employees yet',
    icon: Icons.people_outline,
  );
}
```

**With actions:**

```dart
ErrorState(
  message: 'Connection failed',
  onRetry: () => _retryFetch(),
)

EmptyState(
  message: 'No pending requests',
  action: ElevatedButton(
    onPressed: () => _showDebugInfo(context),
    child: const Text('Show Debug Info'),
  ),
)
```

---

### 4. DetailRow

Key-value pair display widget.

**Before:**

```dart
Padding(
  padding: const EdgeInsets.symmetric(vertical: 6),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 110,
        child: Text(
          'Email',
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          email,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    ],
  ),
)
```

**After:**

```dart
DetailRow(label: 'Email', value: email)
```

**With custom label width:**

```dart
DetailRow(
  label: 'Phone Number',
  value: '+1-234-567-8900',
  labelWidth: 120,
)
```

---

### 5. ActionButtonsRow

Approve/Reject button pair for employee requests.

**Before:**

```dart
Row(
  mainAxisAlignment: MainAxisAlignment.end,
  children: [
    OutlinedButton.icon(
      onPressed: () => _rejectEmployee(context, id),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red,
        side: const BorderSide(color: Colors.red),
      ),
      icon: const Icon(Icons.close, size: 18),
      label: const Text('Reject'),
    ),
    const SizedBox(width: 12),
    ElevatedButton.icon(
      onPressed: () => _approveEmployee(context, id),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF6F00),
        foregroundColor: Colors.white,
      ),
      icon: const Icon(Icons.check_circle, size: 18),
      label: const Text('Approve'),
    ),
  ],
)
```

**After:**

```dart
ActionButtonsRow(
  onReject: () => _rejectEmployee(context, id),
  onApprove: () => _approveEmployee(context, id),
)
```

**With custom labels:**

```dart
ActionButtonsRow(
  rejectLabel: 'Deny',
  approveLabel: 'Accept',
  onReject: () {},
  onApprove: () {},
)
```

---

### 6. FixedBottomButton

Fixed position button at bottom of screen.

**Before:**

```dart
Positioned(
  left: 0,
  right: 0,
  bottom: 0,
  child: Container(
    decoration: BoxDecoration(
      color: const Color(0xFF2C2C2C),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, -2),
        ),
      ],
    ),
    padding: const EdgeInsets.all(16),
    child: SizedBox(
      height: 56,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.push(...),
        style: ElevatedButton.styleFrom(...),
        icon: const Icon(Icons.pending_actions),
        label: const Text('Pending Requests'),
      ),
    ),
  ),
)
```

**After:**

```dart
FixedBottomButton(
  label: 'Pending Requests',
  icon: Icons.pending_actions,
  onPressed: () => Navigator.push(...),
)
```

**With custom colors:**

```dart
FixedBottomButton(
  label: 'Save',
  icon: Icons.save,
  backgroundColor: Colors.green,
  textColor: Colors.white,
  onPressed: () => _save(),
)
```

---

### 7. NavigationMenuConfig

Centralized menu configuration for navigation.

**Before:**

```dart
// Drawer
ListView(
  children: [
    ListTile(
      leading: const Icon(Icons.dashboard),
      title: const Text('Dashboard'),
      onTap: () => _onItemTapped(0),
    ),
    ListTile(
      leading: const Icon(Icons.list),
      title: const Text('Orders'),
      onTap: () => _onItemTapped(1),
    ),
    // ... repeat for each item
  ],
)

// Bottom Navigation
BottomNavigationBar(
  items: const [
    BottomNavigationBarItem(
      icon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.list),
      label: 'Orders',
    ),
    // ... repeat for each item
  ],
)
```

**After:**

```dart
// Drawer - uses single config
ListView(
  children: [
    ...NavigationMenuConfig.items.map((item) => ListTile(
      leading: Icon(item.icon),
      title: Text(item.label),
      onTap: () => _onItemTapped(item.index),
    )),
  ],
)

// Bottom Navigation - uses same config
BottomNavigationBar(
  items: NavigationMenuConfig.items
      .map((item) => BottomNavigationBarItem(
        icon: Icon(item.icon),
        label: item.label,
      ))
      .toList(),
)
```

---

## Employee Service Usage

### Service Injection

```dart
class _PendingEmployeeRequestsPageState extends State<PendingEmployeeRequestsPage> {
  late final EmployeeService _employeeService = EmployeeService();
}
```

### Get Employees Stream

```dart
StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
  stream: _employeeService.getEmployeesStream(widget.adminId),
  builder: (context, snapshot) {
    // Use snapshot data
  },
)
```

### Get Pending Employees Stream

```dart
StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
  stream: _employeeService.getPendingEmployeesStream(widget.adminId),
  builder: (context, snapshot) {
    // Use snapshot data
  },
)
```

### Approve Employee

```dart
Future<void> _approveEmployee(String userId) async {
  try {
    await _employeeService.approveEmployee(userId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Employee approved')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}
```

### Reject Employee

```dart
Future<void> _rejectEmployee(String userId) async {
  try {
    await _employeeService.rejectEmployee(userId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request rejected')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}
```

---

## Complete Page Example

**Before (EmployeesListPage - cluttered):**

```dart
class _EmployeesListPageState extends State<EmployeesListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Employees')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.usersCollection)
            .where('userType', isEqualTo: AppConstants.userTypeEmployee)
            .where('adminId', isEqualTo: widget.adminId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final employees = snapshot.data?.docs ?? [];

          if (employees.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.people_outline, size: 64),
                  SizedBox(height: 12),
                  Text('No employees'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: employees.length,
            itemBuilder: (context, index) {
              final data = employees[index].data();
              final name = data['username'] ?? 'Unknown';

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFFF6F00),
                    child: Text(name[0]),
                  ),
                  title: Text(name),
                  // ...
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showEmployeeDetails(context, data) {
    // 100+ lines of detail modal code
  }

  Widget _detailRow(String label, String value) {
    // Detail row implementation
  }
}
```

**After (EmployeesListPage - clean):**

```dart
class _EmployeesListPageState extends State<EmployeesListPage> {
  late final EmployeeService _employeeService = EmployeeService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Employees')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _employeeService.getEmployeesStream(widget.adminId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingState();
          }

          if (snapshot.hasError) {
            return ErrorState(message: 'Failed to load employees');
          }

          final employees = snapshot.data?.docs ?? [];

          if (employees.isEmpty) {
            return const EmptyState(
              message: 'No employees yet',
              icon: Icons.people_outline,
            );
          }

          return ListView.separated(
            itemCount: employees.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final data = employees[index].data();
              final name = (data['username'] ?? 'Unnamed') as String;
              final email = (data['email'] ?? 'N/A') as String;

              return DashboardCard(
                child: ListTile(
                  leading: UserAvatar(name: name),
                  title: Text(name, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(email, style: const TextStyle(color: Colors.white70)),
                  onTap: () => _showEmployeeDetails(context, data),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showEmployeeDetails(BuildContext context, Map<String, dynamic> data) {
    // 50 lines - simplified with DetailRow and UserAvatar
  }
}
```

---

## Testing Example

**Service Testing (now possible with EmployeeService):**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('EmployeeService', () {
    test('generateUniqueEmployeeId returns 6-digit ID', () async {
      final service = EmployeeService();
      final id = await service.generateUniqueEmployeeId();

      expect(id, matches(RegExp(r'^\d{6}$')));
    });

    test('approveEmployee updates Firestore', () async {
      // Mock Firestore
      final service = EmployeeService();

      // Test implementation
      expect(true, true);
    });
  });
}
```

---

## Migration Checklist

If applying this pattern to other pages:

- [ ] Extract common card patterns to DashboardCard
- [ ] Extract common avatar patterns to UserAvatar
- [ ] Extract state widgets (Loading/Error/Empty)
- [ ] Create service layer for business logic
- [ ] Replace duplicate queries with service methods
- [ ] Extract repeating button patterns
- [ ] Centralize configuration data
- [ ] Add documentation comments
- [ ] Test all components
- [ ] Update imports in all pages
