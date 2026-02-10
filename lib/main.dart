import 'package:cementdeliverytracker/core/constants/app_constants.dart';
import 'package:cementdeliverytracker/core/di/dependency_injection.dart';
import 'package:cementdeliverytracker/core/theme/app_colors.dart';
import 'package:cementdeliverytracker/core/theme/app_theme.dart';
import 'package:cementdeliverytracker/core/theme/theme_provider.dart';
import 'package:cementdeliverytracker/features/auth/presentation/pages/login_page.dart';
import 'package:cementdeliverytracker/features/auth/presentation/pages/signup_page.dart';
import 'package:cementdeliverytracker/features/auth/presentation/pages/splash_page.dart';
import 'package:cementdeliverytracker/features/auth/domain/entities/auth_entities.dart';
import 'package:cementdeliverytracker/features/auth/presentation/pages/role_selection_page.dart';
import 'package:cementdeliverytracker/features/auth/presentation/providers/auth_notifier.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/pages/admin/pages/admin_dashboard_page.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/pages/employee_dashboard_page.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/pages/pending_approval_page.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/pages/super_admin_dashboard_page.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cementdeliverytracker/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Firebase App Check
  // Using playIntegrity for Android (production) and debug for iOS during development
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.debug,
  );

  // Enable Firestore offline persistence for better performance and reduced network dependency
  // This allows the app to function with cached data when offline
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ...DependencyInjection.getProviders(),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            routes: {
              AppConstants.routeLogin: (context) => const LoginPage(),
              AppConstants.routeSignup: (context) => const SignupPage(),
              AppConstants.routePendingApproval: (context) =>
                  const PendingApprovalPage(),
              AppConstants.routeSuperAdminDashboard: (context) =>
                  const SuperAdminDashboardPage(),
              AppConstants.routeAdminDashboard: (context) =>
                  const AdminDashboardPage(),
              AppConstants.routeEmployeeDashboard: (context) =>
                  const EmployeeDashboardPage(),
            },
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _lastUserId;
  String? _lastUserType;

  void _maybeShowApprovalSnack(String userId, String userType) {
    if (_lastUserId != userId) {
      _lastUserId = userId;
      _lastUserType = userType;
      return;
    }

    final wasPending =
        _lastUserType == AppConstants.userTypePending ||
        _lastUserType == AppConstants.userTypePendingEmployee;
    final isApproved =
        userType == AppConstants.userTypeAdmin ||
        userType == AppConstants.userTypeEmployee;

    if (wasPending && isApproved) {
      final roleLabel = userType == AppConstants.userTypeAdmin
          ? 'Admin'
          : 'Employee';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.onPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your account was approved as $roleLabel.',
                    style: const TextStyle(color: AppColors.onPrimary),
                  ),
                ),
              ],
            ),
          ),
        );
      });
    }

    _lastUserType = userType;
  }

  @override
  Widget build(BuildContext context) {
    final authNotifier = context.read<AuthNotifier>();

    return StreamBuilder<AuthUser?>(
      stream: authNotifier.authStateChanges,
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashPage();
        }

        if (snapshot.hasError) {
          return _AuthGateErrorPage(
            message: 'Failed to check login state. Please try again.',
            onRetry: () => setState(() {}),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          _lastUserId = null;
          _lastUserType = null;
          return const LoginPage();
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection(AppConstants.usersCollection)
              .doc(user.id)
              .snapshots(),
          builder: (ctx, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const SplashPage();
            }

            if (userSnapshot.hasError) {
              return _AuthGateErrorPage(
                message: 'Failed to load your profile. Please try again.',
                onRetry: () => setState(() {}),
              );
            }

            final doc = userSnapshot.data;
            if (doc == null || !doc.exists) {
              return const _MissingProfilePage();
            }

            final data = doc.data();
            final userType =
                (data?['userType'] as String?) ?? AppConstants.userTypePending;
            _maybeShowApprovalSnack(user.id, userType);

            switch (userType) {
              case AppConstants.userTypeSuperAdmin:
                return const SuperAdminDashboardPage();
              case AppConstants.userTypeAdmin:
                return const AdminDashboardPage();
              case AppConstants.userTypeEmployee:
                return const EmployeeDashboardPage();
              case AppConstants.userTypeTempEmployee:
                return const RoleSelectionPage();
              case AppConstants.userTypePending:
              case AppConstants.userTypePendingEmployee:
                return const PendingApprovalPage();
              default:
                return const PendingApprovalPage();
            }
          },
        );
      },
    );
  }
}

class _AuthGateErrorPage extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _AuthGateErrorPage({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissingProfilePage extends StatelessWidget {
  const _MissingProfilePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Your account profile could not be loaded.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
              ),
              const SizedBox(height: 12),
              const Text(
                'Please try again, or contact an administrator.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pushReplacementNamed(AppConstants.routeLogin);
                    },
                    child: const Text('Back to login'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      context.read<AuthNotifier>().logout();
                    },
                    child: const Text('Logout'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
