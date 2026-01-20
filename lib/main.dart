import 'package:cementdeliverytracker/core/constants/app_constants.dart';
import 'package:cementdeliverytracker/core/di/dependency_injection.dart';
import 'package:cementdeliverytracker/core/theme/app_theme.dart';
import 'package:cementdeliverytracker/features/auth/presentation/pages/login_page.dart';
import 'package:cementdeliverytracker/features/auth/presentation/pages/signup_page.dart';
import 'package:cementdeliverytracker/features/auth/presentation/pages/splash_page.dart';
import 'package:cementdeliverytracker/features/auth/domain/entities/auth_entities.dart';
import 'package:cementdeliverytracker/features/auth/presentation/pages/role_selection_page.dart';
import 'package:cementdeliverytracker/features/auth/presentation/providers/auth_notifier.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/pages/admin_dashboard_page.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/pages/employee_dashboard_page.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/pages/pending_approval_page.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/pages/super_admin_dashboard_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cementdeliverytracker/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Firebase App Check
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: DependencyInjection.getProviders(),
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
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
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authNotifier = context.read<AuthNotifier>();

    return StreamBuilder<AuthUser?>(
      stream: authNotifier.authStateChanges,
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashPage();
        }

        final user = snapshot.data;
        if (user == null) {
          return const LoginPage();
        }

        return FutureBuilder<Map<String, dynamic>?>(
          future: _getUserData(user.id),
          builder: (ctx, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const SplashPage();
            }

            final userData = userSnapshot.data;
            if (userData == null) {
              return const _MissingProfilePage();
            }

            final userType =
                userData['userType'] ?? AppConstants.userTypePending;
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

class _MissingProfilePage extends StatelessWidget {
  const _MissingProfilePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1C),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Your account profile could not be loaded.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 12),
              const Text(
                'Please try again, or contact an administrator.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
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

Future<Map<String, dynamic>?> _getUserData(String userId) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .get();

    if (doc.exists) {
      return doc.data();
    }
    return null;
  } catch (_) {
    return null;
  }
}
