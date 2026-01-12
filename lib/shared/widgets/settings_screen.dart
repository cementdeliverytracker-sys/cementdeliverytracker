import 'package:cementdeliverytracker/features/auth/presentation/providers/auth_notifier.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:cementdeliverytracker/shared/widgets/change_password_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkTheme = true; // Dummy state for theme toggle

  @override
  void initState() {
    super.initState();
    // Load user data when the widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authNotifier = context.read<AuthNotifier>();
      final currentUser = authNotifier.user;
      if (currentUser != null) {
        context.read<DashboardProvider>().loadUserData(currentUser.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboardProvider, _) {
        final userData = dashboardProvider.userData;
        final role = userData?.userType ?? 'admin';

        if (userData == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  dashboardProvider.errorMessage ?? 'Loading profile...',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          );
        }

        return Container(
          color: const Color(0xFF2C2C2C),
          child: ListView(
            children: [
              // Profile Info Section
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Profile Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person, color: Colors.white),
                title: Text(
                  'Username: ${userData.username}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.email, color: Colors.white),
                title: Text(
                  'Email: ${userData.email}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const Divider(color: Colors.white24),

              // Theme Toggle
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Appearance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              SwitchListTile(
                title: const Text(
                  'Dark Theme',
                  style: TextStyle(color: Colors.white),
                ),
                value: _isDarkTheme,
                onChanged: (value) {
                  setState(() {
                    _isDarkTheme = value;
                    // TODO: Implement actual theme toggle logic
                  });
                },
                activeThumbColor: const Color(0xFFFF6F00),
              ),
              const Divider(color: Colors.white24),

              // Account Settings
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Account',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.lock, color: Colors.white),
                title: const Text(
                  'Change Password',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => const ChangePasswordDialog(),
                  );
                },
              ),

              // Role-based sections
              if (role == 'super_admin') ...[
                ListTile(
                  leading: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                  ),
                  title: const Text(
                    'Manage Admins',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    // TODO: Navigate to manage admins screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Manage Admins tapped')),
                    );
                  },
                ),
              ],

              ListTile(
                leading: const Icon(Icons.logout, color: Colors.white),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  await context.read<AuthNotifier>().logout();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
