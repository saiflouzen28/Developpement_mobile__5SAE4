import 'package:elearning_events_app/views/screens/admin/pack_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constant/app_route.dart';
import '../../../core/constant/app_theme.dart';
import '../../../database/database_helper.dart';
import '../../../providers/auth_provider.dart';

import 'statistics_screen.dart'; // <-- 1. IMPORT THE NEW STATISTICS SCREEN
import 'manage_quizzes_screen.dart';

import 'AdminStatsScreen.dart';
import 'course_management_screen.dart';
import 'manage_events_screen.dart';
import '../../../services/statistics_service.dart';
// import 'manage_users_screen.dart'; // si tu as déjà ton vrai screen
import 'manage_courses_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  List<Widget>? _adminPages; // make it nullable
  late StatisticsService statsService;

  @override
  void initState() {
    super.initState();
    _initDatabaseAndService();
  }

  Future<void> _initDatabaseAndService() async {
    final db = await DatabaseHelper.instance.database;
    statsService = StatisticsService(db);

    setState(() {
      _adminPages = [
        const _DashboardHomeContent(),
        const StatisticsScreen(),
        const ManageQuizzesScreen(),
        const ManageEventsScreen(),
        const CourseManagementScreen(),
        const PackManagementScreen(),
        const ManageCoursesScreen(),
        const ManageUsersScreen(),
        AdminStatsScreen(statsService: statsService),
      ];
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Show loading until _adminPages is initialized
    if (_adminPages == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle(_selectedIndex)),
        backgroundColor: AppTheme.errorColor,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              authProvider.logout();
              Navigator.of(context, rootNavigator: true)
                  .pushReplacementNamed(AppRoute.signIn);
            },
          ),
        ],
      ),
      body: _adminPages![_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Statistics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz_outlined),
            activeIcon: Icon(Icons.quiz),
            label: 'Quizzes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note_outlined),
            activeIcon: Icon(Icons.event_note),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.picture_as_pdf_outlined),
            activeIcon: Icon(Icons.picture_as_pdf),
            label: 'Cours',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_outlined),
            activeIcon: Icon(Icons.account_box_outlined),
            label: 'Pack',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: 'Cours',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_outlined),
            activeIcon: Icon(Icons.people_alt),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return 'Admin Dashboard';
      case 1:
        return 'Statistics & Analytics';
      case 2:
        return 'Quizzes';
      case 3:
        return 'Manage Events';
      case 4:
        return 'Gérer les cours';
      case 5:
        return 'Gérer les pack';
      case 6:
        return 'Gérer les Cours';
      case 7:
        return 'Manage Users';
      case 8:
        return 'Statistiques Admin';
      default:
        return 'Admin';
    }
  }
}

// YOUR ORIGINAL _DashboardHomeContent WIDGET REMAINS UNCHANGED AND IS CORRECT
class _DashboardHomeContent extends StatelessWidget {
  const _DashboardHomeContent();
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.admin_panel_settings_rounded, size: 100, color: AppTheme.errorColor),
            const SizedBox(height: 20),
            Text("Welcome, Admin!", style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 8),
            Text(authProvider.user?.email ?? 'Admin Email',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.lightTextSecondary),
            ),
            const SizedBox(height: 40),
            Text("Select an option from the bottom navigation bar to get started.",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

// YOUR DUMMY ManageUsersScreen WIDGET REMAINS UNCHANGED AND IS CORRECT
class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text("User Management Coming Soon!", style: TextStyle(fontSize: 22, color: Colors.grey)),
        ],
      ),
    );
  }
}
