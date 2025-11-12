import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:animate_do/animate_do.dart';
import '../../../services/content_scraper_service.dart';
import '../../../models/external_article_model.dart';

/// Discover Screen - Display external e-learning articles
/// Can show related articles based on topics from a post
class DiscoverScreen extends StatefulWidget {
  final List<String>? relatedTopics; // Topics extracted from post
  
  const DiscoverScreen({Key? key, this.relatedTopics}) : super(key: key);

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> with SingleTickerProviderStateMixin {
  List<ExternalArticle> _articles = [];
  bool _isLoading = false;
  String _selectedCategory = 'all';
  late TabController _tabController;
  bool _isShowingRelated = false;

  final List<Map<String, dynamic>> _categories = [
    {'id': 'all', 'name': 'All', 'icon': Icons.grid_view},
    {'id': 'programming', 'name': 'Programming', 'icon': Icons.code},
    {'id': 'flutter', 'name': 'Flutter', 'icon': Icons.flutter_dash},
    {'id': 'javascript', 'name': 'JavaScript', 'icon': Icons.javascript},
    {'id': 'python', 'name': 'Python', 'icon': Icons.data_object},
    {'id': 'machine-learning', 'name': 'ML/AI', 'icon': Icons.psychology},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    
    // If related topics provided, show related articles first
    if (widget.relatedTopics != null && widget.relatedTopics!.isNotEmpty) {
      _isShowingRelated = true;
      _loadRelatedArticles();
    } else {
      _loadArticles();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadArticles() async {
    setState(() {
      _isLoading = true;
      _isShowingRelated = false;
    });

    try {
      List<Map<String, dynamic>> fetchedArticles;
      
      if (_selectedCategory == 'all') {
        fetchedArticles = await ContentScraperService.fetchAllArticles();
      } else {
        fetchedArticles = await ContentScraperService.fetchByCategory(_selectedCategory);
      }

      setState(() {
        _articles = fetchedArticles
            .map((json) => ExternalArticle.fromJson(json))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Failed to load articles'),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadRelatedArticles() async {
    if (widget.relatedTopics == null || widget.relatedTopics!.isEmpty) {
      _loadArticles();
      return;
    }

    setState(() {
      _isLoading = true;
      _isShowingRelated = true;
    });

    try {
      final fetchedArticles = await ContentScraperService.fetchRelatedArticles(
        topics: widget.relatedTopics!,
        limit: 20,
      );

      setState(() {
        _articles = fetchedArticles
            .map((json) => ExternalArticle.fromJson(json))
            .toList();
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Loaded ${_articles.length} articles'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Failed to load articles'),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openArticle(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open article')),
      );
    }
  }

  Color _getSourceColor(String source) {
    switch (source.toLowerCase()) {
      case 'freecodecamp':
        return const Color(0xFF0a0a23);
      case 'medium':
        return const Color(0xFF00ab6c);
      case 'dev.to':
        return Colors.black87;
      case 'hashnode':
        return const Color(0xFF2962ff);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 140,
              floating: false,
              pinned: true,
              elevation: 0,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.purple.shade600,
                      Colors.blue.shade600,
                    ],
                  ),
                ),
                child: FlexibleSpaceBar(
                  title: Text(
                    'Discover',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  centerTitle: false,
                  background: Container(
                    padding: const EdgeInsets.only(left: 16, top: 80, right: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Latest Articles',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'From FreeCodeCamp, Medium, Dev.to & more',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _loadArticles,
                  tooltip: 'Refresh',
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicatorColor: Colors.purple.shade600,
                    labelColor: Colors.purple.shade600,
                    unselectedLabelColor: Colors.grey,
                    labelStyle: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    onTap: (index) {
                      setState(() {
                        _selectedCategory = _categories[index]['id'];
                      });
                      _loadArticles();
                    },
                    tabs: _categories.map((category) {
                      return Tab(
                        icon: Icon(category['icon'], size: 20),
                        text: category['name'],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ];
        },
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    // Show banner if displaying related articles
    Widget? banner;
    if (_isShowingRelated && widget.relatedTopics != null) {
      banner = Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade100, Colors.blue.shade100],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.purple.shade300, width: 2),
        ),
        child: Row(
          children: [
            Icon(Icons.lightbulb, color: Colors.purple.shade600, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🎯 Showing articles related to your post',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Topics: ${widget.relatedTopics!.join(", ")}',
                    style: GoogleFonts.poppins(
                      color: Colors.purple.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: _loadArticles,
              child: Text(
                'Browse All',
                style: GoogleFonts.poppins(
                  color: Colors.purple.shade600,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.purple.shade600),
            ),
            const SizedBox(height: 16),
            Text(
              'Fetching articles...',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_articles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No articles found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pull down to refresh',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadArticles,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade600,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _isShowingRelated ? _loadRelatedArticles : _loadArticles,
      color: Colors.purple.shade600,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _articles.length + (banner != null ? 1 : 0),
        itemBuilder: (context, index) {
          // Show banner at top if available
          if (banner != null && index == 0) {
            return banner;
          }
          
          final articleIndex = banner != null ? index - 1 : index;
          final article = _articles[articleIndex];
          return FadeInUp(
            duration: Duration(milliseconds: 300 + (articleIndex * 50)),
            child: _buildArticleCard(article),
          );
        },
      ),
    );
  }

  Widget _buildArticleCard(ExternalArticle article) {
    final sourceColor = _getSourceColor(article.source);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _openArticle(article.url),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image (if available)
            if (article.imageUrl != null && article.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  article.imageUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 180,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [sourceColor, sourceColor.withOpacity(0.7)],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.article,
                          size: 60,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    );
                  },
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Source badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: sourceColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: sourceColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              article.getSourceIcon(),
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              article.source,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: sourceColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        article.getFormattedDate(),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Title
                  Text(
                    article.title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Description
                  Text(
                    article.description,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 16),

                  // Action button
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openArticle(article.url),
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: const Text('Read Article'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: sourceColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          // TODO: Add to favorites
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Saved to favorites!'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        icon: const Icon(Icons.bookmark_border),
                        color: Colors.grey.shade600,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
