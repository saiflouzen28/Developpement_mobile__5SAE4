import 'dart:io';

import 'package:elearning_events_app/views/screens/postulation/post_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import '../../../core/constant/app_route.dart';
import '../../../core/constant/app_theme.dart';
import '../../../models/postulation_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/posts_provider.dart';
import '../../../providers/notifications_provider.dart';
import '../../../database/database_helper.dart';
import 'create_post_screen.dart';
import 'package:animate_do/animate_do.dart';
import '../discover/discover_screen.dart';


class PostsListScreen extends StatefulWidget {
  const PostsListScreen({super.key});

  @override
  State<PostsListScreen> createState() => _PostsListScreenState();
}

class _PostsListScreenState extends State<PostsListScreen> {
  final _searchController = TextEditingController();
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PostsProvider>(context, listen: false).loadPosts();
      
      // Load notifications for current user
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        Provider.of<NotificationsProvider>(context, listen: false)
            .loadNotifications(authProvider.user!.id!);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onNavigationItemTapped(int index) {
    final postsProvider = Provider.of<PostsProvider>(context, listen: false);

    switch (index) {
      case 0:
        break; // Already on posts
      case 1:
        // Navigate to Discover screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DiscoverScreen(),
          ),
        );
        break;
      case 2:
      // Transforme la liste d'IDs en liste de Post
        List<Post> favoritePosts = postsProvider.posts
            .where((post) => postsProvider.favoritePosts.contains(post.id))
            .toList();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FavoritesScreen(posts: favoritePosts),
          ),
        );
        break;
      case 3:
        Navigator.pushReplacementNamed(context, AppRoute.profile);
        break;
    }
  }



  @override
  Widget build(BuildContext context) {
    final postsProvider = Provider.of<PostsProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () => postsProvider.refreshPosts(),
        color: AppTheme.primaryColor,
        child: CustomScrollView(
          slivers: [
            // Modern App Bar
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: AppTheme.primaryColor,
              actions: [
                // Notification Icon with Badge
                Consumer<NotificationsProvider>(
                  builder: (context, notificationsProvider, _) {
                    return Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_rounded, color: Colors.white),
                          onPressed: () {
                            Navigator.pushNamed(context, AppRoute.notifications);
                          },
                        ),
                        if (notificationsProvider.unreadCount > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Text(
                                notificationsProvider.unreadCount > 9 
                                  ? '9+' 
                                  : '${notificationsProvider.unreadCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 40, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          FadeInDown(
                            duration: const Duration(milliseconds: 600),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.explore,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Hi, ${authProvider.user?.prenom ?? 'User'}! 👋',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Discover Posts',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Search and Filter Section
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: postsProvider.searchPosts,
                        decoration: InputDecoration(
                          hintText: 'Search amazing events...',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.grey),
                                  onPressed: () {
                                    _searchController.clear();
                                    postsProvider.searchPosts('');
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Stats and View Toggle
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: FadeInUp(
                  duration: const Duration(milliseconds: 600),
                  delay: const Duration(milliseconds: 200),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Available Posts',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '${postsProvider.posts.length}',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'posts',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (postsProvider.searchQuery.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: TextButton.icon(
                                onPressed: () {
                                  _searchController.clear();
                                  postsProvider.clearFilters();
                                },
                                icon: const Icon(Icons.clear_all, size: 18),
                                label: const Text('Clear'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.primaryColor,
                                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.grid_view_rounded,
                                    color: _isGridView ? AppTheme.primaryColor : Colors.grey,
                                  ),
                                  onPressed: () => setState(() => _isGridView = true),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.view_list_rounded,
                                    color: !_isGridView ? AppTheme.primaryColor : Colors.grey,
                                  ),
                                  onPressed: () => setState(() => _isGridView = false),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Loading state
            if (postsProvider.isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                    strokeWidth: 3,
                  ),
                ),
              )

            // No posts
            else if (postsProvider.posts.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: FadeIn(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.search_off,
                            size: 80,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'No events found',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Try adjusting your search criteria',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )

            // Posts grid/list
            else
              _isGridView
                  ? SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final post = postsProvider.posts[index];
                            return FadeInUp(
                              key: ValueKey(post.id),
                              duration: const Duration(milliseconds: 500),
                              delay: Duration(milliseconds: 50 * index),
                              child: ModernPostCard(post: post),
                            );
                          },
                          childCount: postsProvider.posts.length,
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final post = postsProvider.posts[index];
                            return FadeInUp(
                              key: ValueKey(post.id),
                              duration: const Duration(milliseconds: 500),
                              delay: Duration(milliseconds: 50 * index),
                              child: ModernPostListCard(post: post),
                            );
                          },
                          childCount: postsProvider.posts.length,
                        ),
                      ),
                    ),
          ],
        ),
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          onTap: _onNavigationItemTapped,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: Colors.grey,
          selectedFontSize: 14,
          unselectedFontSize: 12,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Explore',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.article_outlined),
              activeIcon: Icon(Icons.article),
              label: 'Discover',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border),
              activeIcon: Icon(Icons.favorite),
              label: 'Favorites',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final newPost = await Navigator.push<Post>(
            context,
            MaterialPageRoute(
              builder: (_) => const CreatePostScreen(),
            ),
          );
          if (newPost != null) {
            // Post was already added to database in CreatePostScreen, just reload the list
            await postsProvider.loadPosts();
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create'),
        elevation: 4,
      ),
    );
  }
}

// Modern Grid Card
class ModernPostCard extends StatefulWidget {
  final Post post;

  const ModernPostCard({super.key, required this.post});

  @override
  State<ModernPostCard> createState() => _ModernPostCardState();
}

class _ModernPostCardState extends State<ModernPostCard> {
  int _commentCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCommentCount();
  }

  Future<void> _loadCommentCount() async {
    final count = await DatabaseHelper.instance.getCommentCount(widget.post.id!);
    if (mounted) {
      setState(() {
        _commentCount = count;
      });
    }
  }

  String _getTimeAgo(DateTime date) {
    try {
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return "";
    }
  }

  String _formatDate(DateTime date) {
    try {
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: GestureDetector(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailsScreen(post: widget.post),
            ),
          );
          // Refresh comment count and posts list when returning
          _loadCommentCount();
          if (context.mounted) {
            Provider.of<PostsProvider>(context, listen: false).loadPosts();
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 4),
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            children: [
              // Top Section: Heart Icon + Image
              Expanded(
                child: Stack(
                  children: [
                    // Image in the middle
                    Center(
                      child: Container(
                        width: 160,
                        height: 160,
                        margin: const EdgeInsets.only(top: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: widget.post.imagePath != null
                              ? Image.file(
                                  File(widget.post.imagePath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          AppTheme.primaryColor.withOpacity(0.3),
                                          AppTheme.primaryColor.withOpacity(0.1),
                                        ],
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.image_outlined,
                                      size: 50,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppTheme.primaryColor.withOpacity(0.3),
                                        AppTheme.primaryColor.withOpacity(0.1),
                                      ],
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.article_outlined,
                                    size: 50,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    // Heart icon at top right with shadow
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Consumer<PostsProvider>(
                        builder: (context, postsProvider, _) {
                          final isFavorite = postsProvider.isFavorite(widget.post.id!);
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: isFavorite ? Colors.red : Colors.grey[400],
                                size: 22,
                              ),
                              onPressed: () {
                                if (isFavorite) {
                                  postsProvider.removeFavorite(widget.post.id!);
                                } else {
                                  postsProvider.addFavorite(widget.post.id!);
                                }
                              },
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Divider
              Divider(height: 1, thickness: 1, color: Colors.grey[200]),

              // Time & Date Section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 14, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          _getTimeAgo(widget.post.date),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _formatDate(widget.post.date),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.post.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1c1c1c),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Divider
              Divider(height: 1, thickness: 1, color: Colors.grey[200]),

              // Engagement Buttons Section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    // Upvote
                    Expanded(
                      child: _buildEngagementButton(
                        icon: Icons.arrow_upward_rounded,
                        label: '0',
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Comments
                    Expanded(
                      child: _buildEngagementButton(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: '$_commentCount',
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Share
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.link_rounded,
                        size: 18,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEngagementButton({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// Modern List Card
class ModernPostListCard extends StatefulWidget {
  final Post post;

  const ModernPostListCard({super.key, required this.post});

  @override
  State<ModernPostListCard> createState() => _ModernPostListCardState();
}

class _ModernPostListCardState extends State<ModernPostListCard> {
  int _commentCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCommentCount();
  }

  Future<void> _loadCommentCount() async {
    final count = await DatabaseHelper.instance.getCommentCount(widget.post.id!);
    if (mounted) {
      setState(() {
        _commentCount = count;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailsScreen(post: widget.post),
          ),
        );
        // Refresh comment count and posts list when returning
        _loadCommentCount();
        if (context.mounted) {
          Provider.of<PostsProvider>(context, listen: false).loadPosts();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Content on the left
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Time ago and Date
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded, size: 14, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text(
                              _getTimeAgo(widget.post.date),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              widget.post.formattedDate,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Title
                        Text(
                          widget.post.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        
                        // Description
                        Text(
                          widget.post.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        
                        // Tags
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _buildTagsList(),
                        ),
                        const SizedBox(height: 10),
                        
                        // Divider
                        Divider(height: 1, thickness: 1, color: Colors.grey[200]),
                        
                        const SizedBox(height: 10),
                        
                        // Engagement buttons (all three)
                        Row(
                          children: [
                            // Upvote
                            Expanded(
                              child: _buildEngagementButton(
                                icon: Icons.arrow_upward_rounded,
                                label: '0',
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Comments
                            Expanded(
                              child: _buildEngagementButton(
                                icon: Icons.chat_bubble_outline_rounded,
                                label: '$_commentCount',
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Share
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.link_rounded,
                                size: 18,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Image only on the right
                  Container(
                    width: 130,
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: SizedBox(
                                width: 130,
                                height: 160,
                                child: widget.post.imagePath != null
                                    ? Image.file(
                                        File(widget.post.imagePath!),
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              AppTheme.primaryColor.withOpacity(0.4),
                                              AppTheme.primaryColor.withOpacity(0.2),
                                            ],
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.image_outlined, 
                                          color: AppTheme.primaryColor,
                                          size: 50,
                                        ),
                                      ),
                              ),
                            ),
                            // Heart icon inside image
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Consumer<PostsProvider>(
                                builder: (context, postsProvider, _) {
                                  final isFavorite = postsProvider.isFavorite(widget.post.id!);
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      iconSize: 18,
                                      icon: Icon(
                                        isFavorite ? Icons.favorite : Icons.favorite_border,
                                        color: isFavorite ? Colors.red : Colors.grey[400],
                                      ),
                                      onPressed: () {
                                        if (isFavorite) {
                                          postsProvider.removeFavorite(widget.post.id!);
                                        } else {
                                          postsProvider.addFavorite(widget.post.id!);
                                        }
                                      },
                                      padding: const EdgeInsets.all(6),
                                      constraints: const BoxConstraints(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime date) {
    try {
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return "";
    }
  }

  // Build list of tag widgets from post tags
  List<Widget> _buildTagsList() {
    if (widget.post.tags.isEmpty) {
      return [_buildTag('General', AppTheme.primaryColor)];
    }
    
    // Split tags by comma and trim whitespace
    final tagsList = widget.post.tags
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
    
    if (tagsList.isEmpty) {
      return [_buildTag('General', AppTheme.primaryColor)];
    }
    
    // Build a widget for each tag with a color
    return tagsList.asMap().entries.map((entry) {
      final index = entry.key;
      final tag = entry.value;
      return _buildTag(tag, _getTagColor(index));
    }).toList();
  }

  // Get a color for each tag based on index
  Color _getTagColor(int index) {
    final colors = [
      Colors.purple,
      Colors.orange,
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      AppTheme.primaryColor,
    ];
    return colors[index % colors.length];
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEngagementButton({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback onTap;

  const PostCard({super.key, required this.post, required this.onTap});

  String truncate(String text, int maxLength) {
    return text.length <= maxLength ? text : '${text.substring(0, maxLength)}...';
  }

  @override
  Widget build(BuildContext context) {
    return ModernPostCard(post: post);
  }
}






class FavoritesScreen extends StatelessWidget {
  final List<Post> posts;
  const FavoritesScreen({super.key, required this.posts});

  @override
  Widget build(BuildContext context) {
    void _onNavigationItemTapped(int index) {
      switch (index) {
        case 0:
          Navigator.pushReplacementNamed(context, AppRoute.postsList);
          break;
        case 1:
          break;
        case 2:
          Navigator.pushReplacementNamed(context, AppRoute.profile);
          break;
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("My Favorites"),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: posts.isEmpty
          ? Center(
              child: FadeIn(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border,
                        size: 80,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No favorites yet',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Start adding eventss to your favorites',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return FadeInUp(
                  duration: const Duration(milliseconds: 500),
                  delay: Duration(milliseconds: 50 * index),
                  child: ModernPostCard(post: post),
                );
              },
            ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: 1,
          onTap: _onNavigationItemTapped,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Explore',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border),
              activeIcon: Icon(Icons.favorite),
              label: 'Favorites',
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
}

