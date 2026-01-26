class AppConstants {
  // App Info
  static const String appName = 'Cement Delivery Tracker';
  static const String appVersion = '1.0.0';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String enterprisesCollection = 'enterprises';
  static const String distributorsCollection = 'distributors';
  static const String attendanceLogsCollection = 'attendance_logs';

  // User Types
  static const String userTypePending = 'pending';
  static const String userTypePendingEmployee = 'pending_employee';
  static const String userTypeTempEmployee = 'temp_employee';
  static const String userTypeSuperAdmin = 'super_admin';
  static const String userTypeAdmin = 'admin';
  static const String userTypeEmployee = 'employee';

  // Routes
  static const String routeLogin = '/login';
  static const String routeSignup = '/signup';
  static const String routeSplash = '/splash';
  static const String routePendingApproval = '/pending-approval';
  static const String routeSuperAdminDashboard = '/super-admin-dashboard';
  static const String routeAdminDashboard = '/admin-dashboard';
  static const String routeEmployeeDashboard = '/employee-dashboard';

  // Storage
  static const String userImagesPath = 'user_images';
  static const String enterpriseLogosPath = 'enterprise_logos';

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 8.0;
  static const double defaultElevation = 2.0;

  // Validation
  static const int minUsernameLength = 4;
  static const int minPasswordLength = 6;
}
