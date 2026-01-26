import 'package:cementdeliverytracker/features/auth/presentation/providers/auth_notifier.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/pages/admin/pages/employees_tab_page.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/pages/admin/pages/distributors_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// TeamScreen is the main container for the Team section with Employees and Distributors tabs.
class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthNotifier>().user?.id;

    if (userId == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF2C2C2C),
        body: Center(
          child: Text(
            'No admin user found',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFF2C2C2C),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF1E1E1E),
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFFFF6F00),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'Employees'),
                Tab(text: 'Distributors'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                EmployeesTabPage(userId: userId),
                const DistributorsScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
