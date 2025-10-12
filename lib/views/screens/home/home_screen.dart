// lib/views/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';

// Ensure this path is correct for your project structure
import '../../screens/events/events_screen.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/events_provider.dart';
import '../../../core/constant/app_theme.dart';
import '../../../core/constant/app_route.dart';
import '../../../models/user_model.dart';
import '../virtual_room/virtual_room_screen.dart';
// Dummy models for demonstration
class Course {
  final String title;
  final String author;
  final String imageUrl;
  Course({required this.title, required this.author, required this.imageUrl});
}

class BlogPost {
  final String title;
  final String excerpt;
  BlogPost({required this.title, required this.excerpt});
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final List<Course> _featuredCourses = [
    Course(title: 'Advanced Flutter State Management', author: 'Jane Doe', imageUrl: 'assets/images/python_course.jpg'),
    Course(title: 'Introduction to Data Science with Python', author: 'John Smith', imageUrl: 'assets/images/data_science.jpg'),
    Course(title: 'UI/UX Design Fundamentals', author: 'Emily White', imageUrl: 'assets/images/uiux_course.jpg'),
  ];

  final List<BlogPost> _latestBlogPosts = [
    BlogPost(title: '5 Tips for Effective Online Learning', excerpt: 'Maximize your retention and focus with these proven strategies...'),
    BlogPost(title: 'The Future of Mobile Development in 2026', excerpt: 'Discover the upcoming trends that will shape the industry...'),
  ];

  @override
  Widget build(BuildContext context) {
    // Use Provider.of with listen: false for actions and data that don't need to rebuild the whole screen.
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final User? user = authProvider.user;

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(user?.prenom ?? 'Guest', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
              accountEmail: Text(user?.email ?? '', style: const TextStyle(color: Colors.white70)),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  user?.prenom?.substring(0, 1).toUpperCase() ?? 'G',
                  style: const TextStyle(fontSize: 40.0, color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                ),
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // --- FIX #1: THE "HOME" ITEM IS NOW DISABLED ---
            // It has a different style and its onTap is ignored.
            _buildDrawerItem(
              icon: Icons.home, // Use filled icon for current page
              title: 'Home',
              onTap: () {}, // onTap is empty because it will be disabled
              isSelected: true, // This new flag handles the logic
            ),
            _buildDrawerItem(icon: Icons.school_outlined, title: 'Courses', onTap: () { /* TODO */ }),
            _buildDrawerItem(icon: Icons.event_note_outlined, title: 'Events', onTap: () => Navigator.pushNamed(context, AppRoute.events)),
            _buildDrawerItem(icon: Icons.quiz_outlined, title: 'Quizzes & Exams', onTap: () { /* TODO */ }),
            _buildDrawerItem(icon: Icons.article_outlined, title: 'Blog', onTap: () { /* TODO */ }),
            _buildDrawerItem(icon: Icons.workspace_premium_outlined, title: 'Subscription', onTap: () { /* TODO */ }),
            const Divider(thickness: 1, indent: 16, endIndent: 16),
            _buildDrawerItem(icon: Icons.calendar_today_outlined, title: 'My Schedule', onTap: () => Navigator.pushNamed(context, AppRoute.schedule)),
            _buildDrawerItem(icon: Icons.person_outline, title: 'Profile', onTap: () => Navigator.pushNamed(context, AppRoute.profile)),
            const Divider(thickness: 1, indent: 16, endIndent: 16),
            _buildDrawerItem(
              icon: Icons.logout,
              title: 'Logout',
              color: AppTheme.errorColor,
              onTap: () {
                Provider.of<AuthProvider>(context, listen: false).logout();
              },
            ),
          ],
        ),
      ),
      body: Consumer<EventsProvider>(
        builder: (context, eventsProvider, child) {
          final upcomingEvents = eventsProvider.events.where((e) => !e.isFull).take(5).toList();

          return RefreshIndicator(
            onRefresh: () => eventsProvider.refreshEvents(),
            color: AppTheme.primaryColor,
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 150.0,
                  floating: false,
                  pinned: true,
                  backgroundColor: AppTheme.primaryColor,
                  elevation: 2,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    centerTitle: false,
                    title: Text(
                      'Welcome, ${user?.prenom ?? 'Guest'}!',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white, shadows: [Shadow(blurRadius: 2, color: Colors.black26)]),
                    ),
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                ),
                _buildSectionHeader('Quick Actions'),
                SliverToBoxAdapter(
                  child: GridView.count(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: [
                      // In your home_screen.dart, inside the build method

                      _buildCategoryIcon(
                        context,
                        'Virtual Room',
                        Icons.people_alt,
                        Colors.purple,
                            () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              // FINAL FIX #3: Ensure the class name here is correct.
                              builder: (context) => const VirtualRoomScreen3D(roomId: 1),
                            ),
                          );
                        },
                      ),

                      _buildCategoryIcon(context, 'Courses', Icons.school, AppTheme.primaryColor, () { /* TODO */ }),
                      _buildCategoryIcon(context, 'Events', Icons.event, AppTheme.successColor, () => Navigator.pushNamed(context, AppRoute.events)),
                      _buildCategoryIcon(context, 'Quizzes', Icons.quiz, AppTheme.warningColor, () { /* TODO */ }),
                      _buildCategoryIcon(context, 'Blog', Icons.article, AppTheme.accentColor, () { /* TODO */ }),
                    ],
                  ),
                ),
                _buildSectionHeader('Featured Courses', onViewAll: () { /* TODO */ }),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 240,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _featuredCourses.length,
                      itemBuilder: (context, index) {
                        final course = _featuredCourses[index];
                        return _buildCourseCard(course);
                      },
                    ),
                  ),
                ),
                _buildSectionHeader('Upcoming Events', onViewAll: () => Navigator.pushNamed(context, AppRoute.events)),
                if (upcomingEvents.isNotEmpty)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 280,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: upcomingEvents.length,
                        itemBuilder: (context, index) {
                          final event = upcomingEvents[index];
                          return SizedBox(
                            width: 260,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 16.0),
                              child: EventCard(
                                event: event,
                                onTap: () => Navigator.pushNamed(context, AppRoute.eventDetails, arguments: event),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  )
                else
                  _buildEmptyState('No upcoming events right now.'),
                _buildSectionHeader('Latest From The Blog', onViewAll: () { /* TODO */ }),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final post = _latestBlogPosts[index];
                      return _buildBlogPostTile(post);
                    },
                    childCount: _latestBlogPosts.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- FIX #2: THE HELPER METHOD IS NOW SMARTER ---
  ListTile _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
    bool isSelected = false, // Use this flag to indicate the current page
  }) {
    // If the item is selected, give it a different visual style
    final effectiveColor = isSelected ? AppTheme.primaryColor : color;

    return ListTile(
      leading: Icon(icon, color: effectiveColor),
      title: Text(
        title,
        style: TextStyle(
          color: effectiveColor,
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      // If the item is selected, its onTap does nothing. Otherwise, it navigates.
      onTap: isSelected
          ? () => Navigator.pop(context) // Just close the drawer
          : () {
        Navigator.pop(context); // Close drawer first
        onTap(); // Then execute the navigation
      },
      tileColor: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  SliverToBoxAdapter _buildSectionHeader(String title, {VoidCallback? onViewAll}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (onViewAll != null)
              TextButton(
                onPressed: onViewAll,
                child: const Text('View All'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryIcon(BuildContext context, String category, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              category,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard(Course course) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(course.imageUrl, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            course.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            course.author,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBlogPostTile(BlogPost post) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(post.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(post.excerpt, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () { /* TODO: Navigate to blog post details */ },
      ),
    );
  }

  SliverToBoxAdapter _buildEmptyState(String message) {
    return SliverToBoxAdapter(
      child: Container(
        height: 100,
        alignment: Alignment.center,
        child: Text(message, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey)),
      ),
    );
  }
}
