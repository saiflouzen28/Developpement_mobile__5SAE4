import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constant/app_route.dart';
import '../../../core/constant/app_theme.dart';
import '../../../providers/auth_provider.dart';
import 'manage_events_screen.dart';
import 'statistics_screen.dart'; // <-- 1. IMPORT THE NEW STATISTICS SCREEN
import 'manage_quizzes_screen.dart';


class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  // --- 2. ADD THE NEW SCREEN TO THE LIST OF PAGES ---
  // This list now has 4 items. The new StatisticsScreen is second.
  static const List<Widget> _adminPages = <Widget>[
    _DashboardHomeContent(), // Your original "Welcome" screen
    StatisticsScreen(),
    ManageQuizzesScreen(),// The new statistics screen
    ManageEventsScreen(),    // Your existing screen for managing events
    ManageUsersScreen(),     // Your placeholder for user management
       // Quiz management screen// A placeholder for your user management screen
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

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
      body: Center(
        child: _adminPages.elementAt(_selectedIndex),
      ),
      // --- 3. ADD THE NEW ITEM TO THE BOTTOM NAVIGATION BAR ---
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          // --- NEW ITEM FOR STATISTICS ---
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
            icon: Icon(Icons.people_alt_outlined),
            activeIcon: Icon(Icons.people_alt),
            label: 'Users',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.errorColor,
        unselectedItemColor: Colors.grey[700],
        elevation: 8.0,
      ),
    );
  }

  // --- 4. UPDATE THE HELPER TO INCLUDE THE NEW TITLE ---
  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return 'Admin Dashboard';
      case 1:
        return 'Statistics & Analytics'; // Title for the new screen
      case 2:
        return 'Manage Events';
      case 3:
        return 'Manage Users';
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
            const Icon(Icons.admin_panel_settings_rounded,
                size: 100, color: AppTheme.errorColor),
            const SizedBox(height: 20),
            Text(
              "Welcome, Admin!",
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            Text(
              authProvider.user?.email ?? 'Admin Email',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppTheme.lightTextSecondary),
            ),
            const SizedBox(height: 40),
            Text(
              "Select an option from the bottom navigation bar to get started.",
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
          Text(
            "User Management Coming Soon!",
            style: TextStyle(fontSize: 22, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
