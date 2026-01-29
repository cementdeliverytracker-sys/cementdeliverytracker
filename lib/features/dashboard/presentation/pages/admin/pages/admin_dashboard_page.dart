import 'package:cementdeliverytracker/core/theme/app_colors.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/pages/admin/pages/dashboard_screen.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/pages/admin/pages/team_screen.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/pages/admin/pages/reports_screen.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:cementdeliverytracker/features/orders/presentation/pages/orders_list_page.dart';
import 'package:cementdeliverytracker/shared/widgets/settings_screen.dart';
import 'package:flutter/material.dart';

/// AdminDashboardPage is the main navigation container for the admin feature.
/// It manages navigation between different admin screens and layouts.
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;

  late final List<Widget> _screens = [
    const DashboardScreen(),
    const OrdersListPage(),
    const TeamScreen(),
    const ReportsScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: _selectedIndex == 3
            ? null
            : [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.notifications),
                ),
              ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: isLargeScreen
          ? null
          : BottomNavigationBar(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              selectedItemColor: AppColors.primary,
              unselectedItemColor:
                  Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withValues(alpha:  0.6) ??
                  AppColors.textSecondary,
              items: NavigationMenuConfig.items
                  .map(
                    (item) => BottomNavigationBarItem(
                      icon: Icon(item.icon),
                      label: item.label,
                    ),
                  )
                  .toList(),
            ),
      drawer: isLargeScreen
          ? Drawer(
              child: ListView(
                children: [
                  const DrawerHeader(
                    child: Text(
                      'Admin Dashboard',
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                  ...NavigationMenuConfig.items.map(
                    (item) => ListTile(
                      leading: Icon(item.icon),
                      title: Text(item.label),
                      onTap: () {
                        _onItemTapped(item.index);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
