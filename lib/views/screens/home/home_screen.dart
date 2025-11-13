// lib/views/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';

// S'assure que ce chemin est bon pour ton projet
import '../../screens/events/events_screen.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/events_provider.dart';
import '../../../core/constant/app_theme.dart';
import '../../../core/constant/app_route.dart';
import '../../../models/user_model.dart';
import '../games/casino_lobby_screen.dart';
import '../games/games_screen.dart';
import '../virtual_room/virtual_room_screen.dart';
import '../schedule/schedule_screen.dart';
import '../profile/profile_screen.dart';
import '../chatbot/chatbot_screen.dart';

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
  int _currentIndex = 0;
  bool _showChatbot = false;

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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final User? user = authProvider.user;

    return Scaffold(
      body: Stack(
        children: [
          // Only show home content, no IndexedStack
          _buildHomeContent(user),

          // Floating chatbot bubble
          if (!_showChatbot)
            Positioned(
              right: 20,
              bottom: 90,
              child: ZoomIn(
                duration: const Duration(milliseconds: 500),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _showChatbot = true);
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        const Center(
                          child: Text(
                            '🤖',
                            style: TextStyle(fontSize: 28),
                          ),
                        ),
                        // Pulse animation
                        Positioned.fill(
                          child: TweenAnimationBuilder(
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            duration: const Duration(seconds: 2),
                            builder: (context, double value, child) {
                              return Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(1 - value),
                                    width: 2,
                                  ),
                                ),
                              );
                            },
                            onEnd: () {
                              if (mounted) setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Chatbot overlay
          if (_showChatbot)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Column(
                  children: [
                    // Close button
                    SafeArea(
                      child: Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 30,
                          ),
                          onPressed: () {
                            setState(() => _showChatbot = false);
                          },
                        ),
                      ),
                    ),
                    // Chatbot screen
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: const ChatbotScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
              _showChatbot = false; // Close chatbot when navigating
            });

            // Navigate to different screens using routes
            switch (index) {
              case 0:
              // Already on home
                break;
              case 1:
                Navigator.pushNamed(context, AppRoute.events);
                break;
              case 2:
                Navigator.pushNamed(context, AppRoute.schedule);
                break;
              case 3:
                Navigator.pushNamed(context, AppRoute.profile);
                break;
            }
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: Colors.grey,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          elevation: 8,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event_outlined),
              activeIcon: Icon(Icons.event),
              label: 'Events',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: 'Schedule',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  // Build the original home content
  Widget _buildHomeContent(User? user) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                user?.prenom ?? 'Guest',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
              ),
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
            _buildDrawerItem(
              icon: Icons.home,
              title: 'Home',
              onTap: () {},
              isSelected: true,
            ),
            _buildDrawerItem(icon: Icons.school_outlined, title: 'Courses', onTap: () => Navigator.pushNamed(context, AppRoute.courses)),
            _buildDrawerItem(
              icon: Icons.casino,
              title: 'Games',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CasinoLobbyScreen()),
              ),
            ),
            _buildDrawerItem(icon: Icons.quiz_outlined, title: 'Quizzes & Exams', onTap: () => Navigator.pushNamed(context, AppRoute.quizze)),
            _buildDrawerItem(icon: Icons.event_note_outlined, title: 'Events', onTap: () => Navigator.pushNamed(context, AppRoute.events)),
            _buildDrawerItem(icon: Icons.article_outlined, title: 'Postulation', onTap: () => Navigator.pushNamed(context, AppRoute.postsList)),
            _buildDrawerItem(icon: Icons.workspace_premium_outlined, title: 'Subscription', onTap: () { /* TODO */ }),
            const Divider(thickness: 1, indent: 16, endIndent: 16),
            _buildDrawerItem(
              icon: Icons.calendar_today_outlined,
              title: 'My Schedule',
              onTap: () => Navigator.pushNamed(context, AppRoute.schedule),
            ),
            _buildDrawerItem(
              icon: Icons.person_outline,
              title: 'Profile',
              onTap: () => Navigator.pushNamed(context, AppRoute.profile),
            ),
            const Divider(thickness: 1, indent: 16, endIndent: 16),
            _buildDrawerItem(
              icon: Icons.logout,
              title: 'Logout',
              color: AppTheme.errorColor,
              onTap: () => Provider.of<AuthProvider>(context, listen: false).logout(),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 2, color: Colors.black26)],
                      ),
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
                      _buildCategoryIcon(
                        context,
                        'Room',
                        Icons.people_alt,
                        Colors.purple,
                            () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const VirtualRoomScreen3D(roomId: 1),
                            ),
                          );
                        },
                      ),
                      _buildCategoryIcon(context, 'Courses', Icons.school, AppTheme.primaryColor, () => Navigator.pushNamed(context, AppRoute.courses)),
                      _buildCategoryIcon(context, 'Events', Icons.event, AppTheme.successColor, () => Navigator.pushNamed(context, AppRoute.events)),
                      _buildCategoryIcon(context, 'Quizzes', Icons.quiz, AppTheme.warningColor, () => Navigator.pushNamed(context, AppRoute.quizze)),
                      _buildCategoryIcon(context, 'Post', Icons.article, AppTheme.accentColor, () => Navigator.pushNamed(context, AppRoute.postsList)),
                      _buildCategoryIcon(context, 'packs', Icons.event, AppTheme.successColor, () => Navigator.pushNamed(context, AppRoute.PackStoreScreen)),

                    ],
                  ),
                ),
                _buildSectionHeader('Featured Courses', onViewAll: () => Navigator.pushNamed(context, AppRoute.courses)),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 240,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _featuredCourses.length,
                      itemBuilder: (context, index) {
                        final course = _featuredCourses[index];
                        return GestureDetector(
                          // ✅ Bonus: cliquer une carte "Featured" ouvre la liste des cours
                          onTap: () => Navigator.pushNamed(context, AppRoute.courses),
                          child: _buildCourseCard(course),
                        );
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
                _buildSectionHeader('Latest From The Postulation', onViewAll: () { /* TODO */ }),
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

  ListTile _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
    bool isSelected = false,
  }) {
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
      onTap: isSelected
          ? () => Navigator.pop(context)
          : () {
        Navigator.pop(context);
        onTap();
      },
      tileColor: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  SliverToBoxAdapter _buildSectionHeader(String title, {VoidCallback? onViewAll}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            if (onViewAll != null) TextButton(onPressed: onViewAll, child: const Text('View All')),
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
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
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