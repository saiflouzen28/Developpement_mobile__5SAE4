import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constant/app_route.dart';
import '../../../core/constant/app_theme.dart';
import '../../../providers/auth_provider.dart';
import 'manage_events_screen.dart'; // Already imported
// Import your user management screen when you create it
// import 'manage_users_screen.dart';

// --- The AdminDashboardScreen is now a "shell" that manages pages ---
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // --- STATE FOR MANAGING THE SELECTED TAB ---
  int _selectedIndex = 0;

  // --- LIST OF YOUR ADMIN PAGES ---
  static const List<Widget> _adminPages = <Widget>[
    _DashboardHomeContent(), // The original "Welcome, Admin!" content
    ManageEventsScreen(),    // Your existing screen for managing events
    ManageUsersScreen(),     // A placeholder for your user management screen
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
        title: Text(_getAppBarTitle(_selectedIndex)), // Title changes with the page
        backgroundColor: AppTheme.errorColor,
        automaticallyImplyLeading: false, // No back button on the main dashboard
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              authProvider.logout();
              // Use root navigator to ensure we exit the admin section completely
              Navigator.of(context, rootNavigator: true)
                  .pushReplacementNamed(AppRoute.signIn);
            },
          ),
        ],
      ),
      // --- THE BODY NOW SHOWS THE SELECTED ADMIN PAGE ---
      body: Center(
        child: _adminPages.elementAt(_selectedIndex),
      ),
      // --- ADD THE BOTTOM NAVIGATION BAR ---
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
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
        // Style it to match the admin theme
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.errorColor, // Active icon color
        unselectedItemColor: Colors.grey[700],   // Inactive icon color
        elevation: 8.0,
      ),
    );
  }

  // Helper to get the correct AppBar title for each screen
  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return 'Admin Dashboard';
      case 1:
        return 'Manage Events';
      case 2:
        return 'Manage Users';
      default:
        return 'Admin';
    }
  }
}

// --- YOUR ORIGINAL DASHBOARD CONTENT IS MOVED INTO THIS PRIVATE WIDGET ---
class _DashboardHomeContent extends StatelessWidget {
  const _DashboardHomeContent();

  @override
  Widget build(BuildContext context) {
    // We get the provider again here, as this is a new build context
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

// --- DUMMY SCREEN FOR USER MANAGEMENT ---
// You can replace this with your actual `ManageUsersScreen` when you build it.
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
