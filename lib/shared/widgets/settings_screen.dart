import 'package:cementdeliverytracker/core/constants/app_constants.dart';
import 'package:cementdeliverytracker/features/auth/presentation/providers/auth_notifier.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:cementdeliverytracker/shared/widgets/change_password_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
              if (role == AppConstants.userTypeAdmin) ...[
                ListTile(
                  leading: const Icon(Icons.badge, color: Colors.white),
                  title: Text(
                    'Admin ID: ${userData.adminId ?? 'Not assigned'}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Share this ID when needed. It cannot be changed.',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
                _EmployeeCodeCard(userId: userData.userId),
              ],
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

class _EmployeeCodeCard extends StatelessWidget {
  final String userId;

  const _EmployeeCodeCard({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.enterprisesCollection)
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ListTile(
            leading: Icon(Icons.vpn_key, color: Colors.white),
            title: Text(
              'Loading employee code...',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        final data = snapshot.data?.data();
        final adminCode = (data?['adminCode'] ?? '') as String;

        if (adminCode.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Card(
            color: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.vpn_key, size: 20, color: Color(0xFFFF6F00)),
                      SizedBox(width: 8),
                      Text(
                        'Employee Join Code',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Share this code with employees to join your company',
                    style: TextStyle(fontSize: 13, color: Colors.white60),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFFF6F00).withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          adminCode,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                            color: Color(0xFFFF6F00),
                            letterSpacing: 3,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.copy,
                            color: Color(0xFFFF6F00),
                          ),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: adminCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Code copied to clipboard!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          tooltip: 'Copy code',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
