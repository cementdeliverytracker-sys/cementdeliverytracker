import 'package:cementdeliverytracker/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:cementdeliverytracker/shared/widgets/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const OrdersScreen(),
    const EmployeesScreen(),
    const ReportsScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 600;
    final userData = Provider.of<DashboardProvider>(
      context,
      listen: false,
    ).userData;
    final userType = userData?.userType ?? 'admin';
    final String title = userType == 'super_admin'
        ? 'Super Admin Dashboard'
        : 'Admin Dashboard';

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF2C2C2C),
        primaryColor: const Color(0xFFFF6F00),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF6F00),
          secondary: Color(0xFFFF6F00),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: _selectedIndex == 4
              ? null
              : [
                  IconButton(
                    onPressed: () {
                      // TODO: Implement notification functionality
                    },
                    icon: const Icon(Icons.notifications),
                  ),
                ],
        ),
        body: IndexedStack(index: _selectedIndex, children: _screens),
        bottomNavigationBar: isLargeScreen
            ? null
            : BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                selectedItemColor: const Color(0xFFFF6F00),
                unselectedItemColor: Colors.white70,
                backgroundColor: const Color(0xFF2C2C2C),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard),
                    label: 'Dashboard',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.list),
                    label: 'Orders',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.people),
                    label: 'Employees',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.report),
                    label: 'Reports',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.settings),
                    label: 'Settings',
                  ),
                ],
              ),
        drawer: isLargeScreen
            ? Drawer(
                child: ListView(
                  children: [
                    const DrawerHeader(
                      child: Text(
                        'Admin Dashboard',
                        style: TextStyle(color: Colors.white, fontSize: 24),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.dashboard, color: Colors.white),
                      title: const Text('Dashboard'),
                      onTap: () {
                        _onItemTapped(0);
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.list, color: Colors.white),
                      title: const Text('Orders'),
                      onTap: () {
                        _onItemTapped(1);
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.people, color: Colors.white),
                      title: const Text('Employees'),
                      onTap: () {
                        _onItemTapped(2);
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.report, color: Colors.white),
                      title: const Text('Reports'),
                      onTap: () {
                        _onItemTapped(3);
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.settings, color: Colors.white),
                      title: const Text('Settings'),
                      onTap: () {
                        _onItemTapped(4);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Dashboard Screen',
        style: TextStyle(fontSize: 24, color: Colors.white),
      ),
    );
  }
}

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Orders Screen',
        style: TextStyle(fontSize: 24, color: Colors.white),
      ),
    );
  }
}

class EmployeesScreen extends StatelessWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Employees Screen',
        style: TextStyle(fontSize: 24, color: Colors.white),
      ),
    );
  }
}

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Reports Screen',
        style: TextStyle(fontSize: 24, color: Colors.white),
      ),
    );
  }
}
