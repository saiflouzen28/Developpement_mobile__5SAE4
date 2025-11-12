import 'dart:convert';
import 'package:http/http.dart' as http;

/// Content Scraper Service
/// Fetches e-learning articles from RSS feeds and public APIs
/// ✅ Respects robots.txt
/// ✅ Rate-limited (polite scraping)
/// ✅ Uses official RSS feeds (legal)
/// ✅ Context-aware (suggests articles based on post topics)
class ContentScraperService {
  static const String _userAgent = 'ELearningApp/1.0 (Educational Purpose)';
  static DateTime? _lastRequestTime;
  static const Duration _requestDelay = Duration(seconds: 2); // Polite delay

  /// Public RSS Feeds (Legal & Allowed)
  static const Map<String, String> _rssFeedUrls = {
    'freeCodeCamp': 'https://www.freecodecamp.org/news/rss/',
    'medium_programming': 'https://medium.com/feed/tag/programming',
    'medium_elearning': 'https://medium.com/feed/tag/e-learning',
    'dev.to': 'https://dev.to/feed',
    'hashnode': 'https://hashnode.com/rss/',
  };

  /// Topic keywords mapping for intelligent article suggestions
  static const Map<String, List<String>> _topicKeywords = {
    'java': ['java', 'jvm', 'spring', 'kotlin', 'android', 'maven', 'gradle'],
    'javascript': ['javascript', 'js', 'node', 'react', 'vue', 'angular', 'typescript', 'npm'],
    'python': ['python', 'django', 'flask', 'pandas', 'numpy', 'pip', 'fastapi'],
    'flutter': ['flutter', 'dart', 'widget', 'firebase', 'bloc', 'provider'],
    'web': ['html', 'css', 'web', 'frontend', 'backend', 'http', 'rest', 'api'],
    'mobile': ['mobile', 'android', 'ios', 'swift', 'kotlin', 'react native'],
    'database': ['sql', 'database', 'mysql', 'postgresql', 'mongodb', 'redis', 'orm'],
    'ai': ['ai', 'machine learning', 'ml', 'deep learning', 'neural', 'tensorflow', 'pytorch'],
    'devops': ['docker', 'kubernetes', 'ci/cd', 'jenkins', 'aws', 'azure', 'cloud'],
    'security': ['security', 'authentication', 'encryption', 'oauth', 'jwt', 'https'],
  };

  /// Fetch articles from all sources
  static Future<List<Map<String, dynamic>>> fetchAllArticles() async {
    List<Map<String, dynamic>> allArticles = [];

    try {
      // Fetch from FreeCodeCamp RSS
      final freeCodeCampArticles = await _fetchRSSFeed(
        _rssFeedUrls['freeCodeCamp']!,
        'FreeCodeCamp',
      );
      allArticles.addAll(freeCodeCampArticles);

      await _respectRateLimit();

      // Fetch from Medium Programming
      final mediumProgArticles = await _fetchRSSFeed(
        _rssFeedUrls['medium_programming']!,
        'Medium',
      );
      allArticles.addAll(mediumProgArticles);

      await _respectRateLimit();

      // Fetch from Dev.to
      final devToArticles = await _fetchRSSFeed(
        _rssFeedUrls['dev.to']!,
        'Dev.to',
      );
      allArticles.addAll(devToArticles);

      print('✅ Successfully fetched ${allArticles.length} articles');
      return allArticles;
    } catch (e) {
      print('❌ Error fetching articles: $e');
      return [];
    }
  }

  /// Fetch articles from a specific RSS feed
  static Future<List<Map<String, dynamic>>> _fetchRSSFeed(
    String feedUrl,
    String source,
  ) async {
    try {
      print('📡 Fetching RSS feed from $source...');

      final response = await http.get(
        Uri.parse(feedUrl),
        headers: {
          'User-Agent': _userAgent,
          'Accept': 'application/rss+xml, application/xml, text/xml',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final articles = _parseRSSFeed(response.body, source);
        print('✅ Fetched ${articles.length} articles from $source');
        return articles;
      } else {
        print('⚠️ Failed to fetch from $source: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error fetching RSS from $source: $e');
      return [];
    }
  }

  /// Parse RSS XML feed
  static List<Map<String, dynamic>> _parseRSSFeed(String xml, String source) {
    List<Map<String, dynamic>> articles = [];

    try {
      // Simple regex-based XML parsing (for basic RSS feeds)
      final itemRegex = RegExp(r'<item>(.*?)</item>', dotAll: true);
      final items = itemRegex.allMatches(xml);

      for (var match in items.take(10)) {
        // Limit to 10 articles per source
        final itemXml = match.group(1) ?? '';

        final title = _extractTag(itemXml, 'title');
        final link = _extractTag(itemXml, 'link');
        final description = _extractTag(itemXml, 'description');
        final pubDate = _extractTag(itemXml, 'pubDate');
        final image = _extractImageFromContent(itemXml);

        if (title.isNotEmpty && link.isNotEmpty) {
          articles.add({
            'title': _cleanHtml(title),
            'url': link,
            'description': _cleanHtml(description).length > 200
                ? '${_cleanHtml(description).substring(0, 200)}...'
                : _cleanHtml(description),
            'source': source,
            'publishDate': pubDate,
            'imageUrl': image,
            'fetchedAt': DateTime.now().toIso8601String(),
          });
        }
      }
    } catch (e) {
      print('❌ Error parsing RSS feed: $e');
    }

    return articles;
  }

  /// Extract XML tag value
  static String _extractTag(String xml, String tagName) {
    final regex = RegExp('<$tagName>(.*?)</$tagName>', dotAll: true);
    final match = regex.firstMatch(xml);
    return match?.group(1)?.trim() ?? '';
  }

  /// Extract image from content or media tags
  static String _extractImageFromContent(String xml) {
    // Try media:content first
    var regex = RegExp(r'<media:content[^>]*url="([^"]+)"');
    var match = regex.firstMatch(xml);
    if (match != null) return match.group(1) ?? '';

    // Try media:thumbnail
    regex = RegExp(r'<media:thumbnail[^>]*url="([^"]+)"');
    match = regex.firstMatch(xml);
    if (match != null) return match.group(1) ?? '';

    // Try img tag in content
    regex = RegExp(r'<img[^>]*src="([^"]+)"');
    match = regex.firstMatch(xml);
    if (match != null) return match.group(1) ?? '';

    return '';
  }

  /// Clean HTML tags from text
  static String _cleanHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();
  }

  /// Respect rate limiting (polite scraping)
  static Future<void> _respectRateLimit() async {
    if (_lastRequestTime != null) {
      final elapsed = DateTime.now().difference(_lastRequestTime!);
      if (elapsed < _requestDelay) {
        final waitTime = _requestDelay - elapsed;
        print('⏳ Waiting ${waitTime.inMilliseconds}ms before next request...');
        await Future.delayed(waitTime);
      }
    }
    _lastRequestTime = DateTime.now();
  }

  /// Check robots.txt (simplified check)
  static Future<bool> canScrapeDomain(String domain) async {
    try {
      final robotsUrl = 'https://$domain/robots.txt';
      final response = await http.get(
        Uri.parse(robotsUrl),
        headers: {'User-Agent': _userAgent},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final robotsTxt = response.body.toLowerCase();

        // Check if our user agent is disallowed
        if (robotsTxt.contains('user-agent: *')) {
          final disallowPattern = RegExp(r'disallow:\s*(/[^\n]*)', multiLine: true);
          final matches = disallowPattern.allMatches(robotsTxt);

          for (var match in matches) {
            final disallowedPath = match.group(1)?.trim() ?? '';
            if (disallowedPath == '/') {
              print('❌ robots.txt disallows scraping $domain');
              return false;
            }
          }
        }

        print('✅ robots.txt allows scraping $domain');
        return true;
      }

      // If no robots.txt, assume allowed (but be cautious)
      print('⚠️ No robots.txt found for $domain, proceeding cautiously');
      return true;
    } catch (e) {
      print('⚠️ Could not check robots.txt for $domain: $e');
      return true; // Fail open for RSS feeds
    }
  }

  /// Fetch specific category articles
  static Future<List<Map<String, dynamic>>> fetchByCategory(
    String category,
  ) async {
    final categoryFeeds = {
      'programming': 'https://medium.com/feed/tag/programming',
      'flutter': 'https://medium.com/feed/tag/flutter',
      'javascript': 'https://medium.com/feed/tag/javascript',
      'python': 'https://medium.com/feed/tag/python',
      'machine-learning': 'https://medium.com/feed/tag/machine-learning',
      'web-development': 'https://medium.com/feed/tag/web-development',
    };

    final feedUrl = categoryFeeds[category.toLowerCase()];
    if (feedUrl == null) {
      print('⚠️ Unknown category: $category');
      return [];
    }

    return await _fetchRSSFeed(feedUrl, 'Medium - ${category.toUpperCase()}');
  }

  /// Get available sources
  static List<String> getAvailableSources() {
    return _rssFeedUrls.keys.toList();
  }

  /// Test if a source is accessible
  static Future<bool> testSource(String sourceName) async {
    final feedUrl = _rssFeedUrls[sourceName];
    if (feedUrl == null) return false;

    try {
      final response = await http.head(
        Uri.parse(feedUrl),
        headers: {'User-Agent': _userAgent},
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200 || response.statusCode == 405;
    } catch (e) {
      return false;
    }
  }

  /// Extract topics from post content (title, description, tags)
  /// Returns a list of detected topics (e.g., ['java', 'web', 'database'])
  static List<String> extractTopicsFromPost({
    required String title,
    required String description,
    String? tags,
  }) {
    // Combine all text for analysis
    final combinedText = '${title.toLowerCase()} ${description.toLowerCase()} ${tags?.toLowerCase() ?? ''}';
    
    List<String> detectedTopics = [];

    // Check each topic's keywords
    _topicKeywords.forEach((topic, keywords) {
      for (var keyword in keywords) {
        if (combinedText.contains(keyword)) {
          if (!detectedTopics.contains(topic)) {
            detectedTopics.add(topic);
          }
          break; // Found this topic, move to next
        }
      }
    });

    // Also check if tags contain topic names directly
    if (tags != null && tags.isNotEmpty) {
      final tagList = tags.toLowerCase().split(',').map((t) => t.trim()).toList();
      for (var tag in tagList) {
        if (_topicKeywords.containsKey(tag) && !detectedTopics.contains(tag)) {
          detectedTopics.add(tag);
        }
      }
    }

    print('🔍 Extracted topics: $detectedTopics from text: ${combinedText.substring(0, combinedText.length > 50 ? 50 : combinedText.length)}...');
    
    return detectedTopics;
  }

  /// Fetch articles related to specific topics
  /// This is context-aware and suggests articles based on post content
  static Future<List<Map<String, dynamic>>> fetchRelatedArticles({
    required List<String> topics,
    int limit = 10,
  }) async {
    if (topics.isEmpty) {
      print('ℹ️ No topics provided, fetching general articles...');
      return await fetchAllArticles();
    }

    print('🎯 Fetching articles for topics: $topics');
    List<Map<String, dynamic>> relatedArticles = [];

    try {
      // Fetch from category-specific Medium feeds
      for (var topic in topics) {
        if (relatedArticles.length >= limit) break;

        // Map topics to Medium tags
        String mediumTag = _getTopicMediumTag(topic);
        final feedUrl = 'https://medium.com/feed/tag/$mediumTag';

        print('📥 Fetching articles for topic: $topic (tag: $mediumTag)');
        final articles = await _fetchRSSFeed(feedUrl, 'Medium - $topic');
        
        // Mark articles with the related topic
        for (var article in articles) {
          article['relatedTopic'] = topic;
        }
        
        relatedArticles.addAll(articles);
        
        if (topics.indexOf(topic) < topics.length - 1) {
          await _respectRateLimit();
        }
      }

      // Also fetch from Dev.to (general programming)
      if (relatedArticles.length < limit) {
        await _respectRateLimit();
        final devToArticles = await _fetchRSSFeed(
          _rssFeedUrls['dev.to']!,
          'Dev.to',
        );
        relatedArticles.addAll(devToArticles);
      }

      // Shuffle and limit results
      relatedArticles.shuffle();
      return relatedArticles.take(limit).toList();

    } catch (e) {
      print('❌ Error fetching related articles: $e');
      return [];
    }
  }

  /// Map topic to Medium tag
  static String _getTopicMediumTag(String topic) {
    const topicToTag = {
      'java': 'java',
      'javascript': 'javascript',
      'python': 'python',
      'flutter': 'flutter',
      'web': 'web-development',
      'mobile': 'mobile-development',
      'database': 'database',
      'ai': 'machine-learning',
      'devops': 'devops',
      'security': 'cybersecurity',
    };
    
    return topicToTag[topic] ?? 'programming';
  }

  /// Get a quick suggestion message for related articles
  static String getSuggestionMessage(List<String> topics) {
    if (topics.isEmpty) {
      return '💡 Discover more articles to expand your knowledge!';
    }
    
    final topicNames = topics.take(3).join(', ');
    return '💡 Found ${topics.length} topic${topics.length > 1 ? 's' : ''} in your post! Check out related articles about: $topicNames';
  }
}
