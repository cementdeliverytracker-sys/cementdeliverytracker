import 'package:cementdeliverytracker/core/constants/app_constants.dart';
import 'package:cementdeliverytracker/core/di/dependency_injection.dart';
import 'package:cementdeliverytracker/core/theme/app_theme.dart';
import 'package:cementdeliverytracker/features/auth/presentation/pages/login_page.dart';
import 'package:cementdeliverytracker/features/auth/presentation/pages/signup_page.dart';
import 'package:cementdeliverytracker/features/auth/presentation/pages/splash_page.dart';
import 'package:cementdeliverytracker/features/auth/presentation/providers/auth_notifier.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/pages/admin_dashboard_page.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/pages/employee_dashboard_page.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/pages/pending_approval_page.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/pages/super_admin_dashboard_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cementdeliverytracker/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
        },
        home: Consumer<AuthNotifier>(
          builder: (context, authNotifier, child) {
            return StreamBuilder(
              stream: authNotifier.authStateChanges,
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SplashPage();
                }

                if (snapshot.hasData && snapshot.data != null) {
                  final user = snapshot.data!;
                  return FutureBuilder(
                    future: _getUserDashboard(user.id),
                    builder: (ctx, userSnapshot) {
                      if (userSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const SplashPage();
                      }

                      if (userSnapshot.hasError) {
                        return const LoginPage();
                      }

                      final userData = userSnapshot.data;
                      if (userData == null) {
                        return const LoginPage();
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
                        default:
                          return const PendingApprovalPage();
                      }
                    },
                  );
                }

                return const LoginPage();
              },
            );
          },
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _getUserDashboard(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
