import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/comment_model.dart';
import '../models/comment_quality_model.dart';

/// AI-powered comment quality evaluation service
class AICommentRatingService {
  // TODO: Replace with your actual API key
  static const String _apiKey = 'AIzaSyDPF2EBjLdnL7Ym2cvGDHPZkehGc-Yxa5o';
  static const String _geminiEndpoint = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';

  /// Evaluate a single comment's quality
  static Future<CommentQuality> evaluateComment({
    required Comment comment,
    required String postContent,
    String? postTitle,
  }) async {
    try {
      // For now, use intelligent mock evaluation
      // To use real AI, uncomment the API call below
      return _getMockEvaluation(comment, postContent, postTitle);

      // REAL API CALL (uncomment when you have API key):
      // return await _callGeminiAPI(comment, postContent, postTitle);
      
    } catch (e) {
      print('❌ Comment Rating Error: $e');
      return _getFallbackEvaluation(comment);
    }
  }

  /// Batch evaluate multiple comments
  static Future<Map<int, CommentQuality>> evaluateComments({
    required List<Comment> comments,
    required String postContent,
    String? postTitle,
  }) async {
    final results = <int, CommentQuality>{};
    
    for (final comment in comments) {
      if (comment.id != null) {
        final quality = await evaluateComment(
          comment: comment,
          postContent: postContent,
          postTitle: postTitle,
        );
        results[comment.id!] = quality;
      }
    }
    
    return results;
  }

  /// Call Gemini API for real AI evaluation
  static Future<CommentQuality> _callGeminiAPI(
    Comment comment,
    String postContent,
    String? postTitle,
  ) async {
    final prompt = _buildEvaluationPrompt(comment, postContent, postTitle);
    
    final response = await http.post(
      Uri.parse('$_geminiEndpoint?key=$_apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [{
          'parts': [{'text': prompt}]
        }],
        'generationConfig': {
          'temperature': 0.3,
          'maxOutputTokens': 200,
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['candidates'][0]['content']['parts'][0]['text'] as String;
      
      // Parse AI response (expected format: "Relevance:4.5,Clarity:4.0,Constructiveness:3.5,Tone:5.0")
      return _parseAIResponse(comment.id!, text);
    } else {
      throw Exception('API call failed: ${response.statusCode}');
    }
  }

  /// Build prompt for AI evaluation
  static String _buildEvaluationPrompt(
    Comment comment,
    String postContent,
    String? postTitle,
  ) {
    return '''
Evaluate this comment on a 0-5 scale for each criterion:

POST TOPIC: ${postTitle ?? 'Educational Discussion'}
POST CONTENT: $postContent

COMMENT: "${comment.content}"

Provide scores (0.0-5.0) for:
1. RELEVANCE (40% weight): How related is it to the post topic?
2. CLARITY (20% weight): How clear and understandable is it?
3. CONSTRUCTIVENESS (20% weight): Does it add value to the discussion?
4. TONE (20% weight): Is it respectful and appropriate?

Respond ONLY in this format:
Relevance:[score],Clarity:[score],Constructiveness:[score],Tone:[score]

Example: Relevance:4.5,Clarity:4.0,Constructiveness:3.5,Tone:5.0
''';
  }

  /// Parse AI response text
  static CommentQuality _parseAIResponse(int commentId, String response) {
    try {
      final regex = RegExp(r'Relevance:([\d.]+),Clarity:([\d.]+),Constructiveness:([\d.]+),Tone:([\d.]+)');
      final match = regex.firstMatch(response);
      
      if (match != null) {
        return CommentQuality.fromCriteria(
          commentId: commentId,
          relevance: double.parse(match.group(1)!),
          clarity: double.parse(match.group(2)!),
          constructiveness: double.parse(match.group(3)!),
          tone: double.parse(match.group(4)!),
        );
      }
    } catch (e) {
      print('⚠️ Failed to parse AI response: $e');
    }
    
    // Fallback to default
    return CommentQuality.fromCriteria(
      commentId: commentId,
      relevance: 3.0,
      clarity: 3.0,
      constructiveness: 3.0,
      tone: 4.0,
    );
  }

  /// Intelligent mock evaluation (works without API key)
  static CommentQuality _getMockEvaluation(
    Comment comment,
    String postContent,
    String? postTitle,
  ) {
    final content = comment.content.trim().toLowerCase();
    final contentLength = comment.content.trim().length;
    
    // 1. RELEVANCE (40% weight)
    double relevance = 3.0; // Base score
    
    // Check if comment mentions key terms from post
    final postWords = _extractKeywords(postContent);
    final commentWords = _extractKeywords(comment.content);
    final matchCount = postWords.where((word) => commentWords.contains(word)).length;
    
    if (matchCount >= 3) relevance = 4.5;
    else if (matchCount >= 2) relevance = 4.0;
    else if (matchCount >= 1) relevance = 3.5;
    
    // Penalize very short comments
    if (contentLength < 10) relevance = max(1.0, relevance - 1.5);
    
    // 2. CLARITY (20% weight)
    double clarity = 3.0; // Base score
    
    // Check for proper structure
    if (content.contains('?')) clarity += 0.5; // Questions are clear
    if (content.split('.').length > 1) clarity += 0.5; // Multiple sentences
    if (contentLength > 50) clarity += 0.5; // Well-developed
    if (contentLength > 100) clarity += 0.5; // Very detailed
    
    // Penalize unclear patterns
    if (content.contains(RegExp(r'^(ok|okay|yes|no|hmm|mmmm|lol|haha)$'))) {
      clarity = 1.5;
    }
    if (content.replaceAll(RegExp(r'[a-z]'), '').length > contentLength * 0.3) {
      // Too many special chars
      clarity = max(2.0, clarity - 1.0);
    }
    
    clarity = min(5.0, clarity);
    
    // 3. CONSTRUCTIVENESS (20% weight)
    double constructiveness = 3.0; // Base score
    
    // Positive indicators
    final constructivePatterns = [
      'because', 'therefore', 'however', 'additionally', 'furthermore',
      'example', 'instance', 'suggest', 'recommend', 'consider',
      'analysis', 'perspective', 'viewpoint', 'opinion', 'think',
      'believe', 'understand', 'learn', 'helpful', 'useful'
    ];
    
    int constructiveCount = constructivePatterns.where((p) => content.contains(p)).length;
    constructiveness += min(2.0, constructiveCount * 0.4);
    
    // Negative indicators (non-constructive)
    final nonConstructivePatterns = [
      'stupid', 'dumb', 'idiot', 'waste', 'useless', 'boring',
      'hate', 'worst', 'terrible', 'awful', 'garbage'
    ];
    
    if (nonConstructivePatterns.any((p) => content.contains(p))) {
      constructiveness = max(1.0, constructiveness - 2.0);
    }
    
    // Very short = low constructiveness
    if (contentLength < 15) constructiveness = max(1.5, constructiveness - 1.5);
    
    constructiveness = min(5.0, max(1.0, constructiveness));
    
    // 4. TONE (20% weight)
    double tone = 4.0; // Base score (assume respectful)
    
    // Positive tone indicators
    final positiveWords = [
      'thank', 'please', 'appreciate', 'respect', 'agree',
      'understand', 'excellent', 'great', 'good', 'nice',
      'helpful', 'interesting', 'valuable'
    ];
    
    if (positiveWords.any((w) => content.contains(w))) tone += 0.5;
    
    // Negative tone indicators
    final negativeWords = [
      'stupid', 'idiot', 'dumb', 'shut up', 'hate', 'suck',
      'terrible', 'awful', 'garbage', 'trash', 'worst',
      'ridiculous', 'pathetic', 'loser'
    ];
    
    if (negativeWords.any((w) => content.contains(w))) {
      tone = max(1.0, tone - 3.0);
    }
    
    // Excessive caps = aggressive tone
    final capsCount = content.replaceAll(RegExp(r'[^A-Z]'), '').length;
    if (capsCount > contentLength * 0.5 && contentLength > 5) {
      tone = max(2.0, tone - 1.5);
    }
    
    // Multiple exclamation marks = aggressive
    if (content.contains('!!!') || content.contains('!?')) {
      tone = max(2.5, tone - 1.0);
    }
    
    tone = min(5.0, max(1.0, tone));
    
    return CommentQuality.fromCriteria(
      commentId: comment.id!,
      relevance: _roundScore(relevance),
      clarity: _roundScore(clarity),
      constructiveness: _roundScore(constructiveness),
      tone: _roundScore(tone),
    );
  }

  /// Fallback evaluation when everything fails
  static CommentQuality _getFallbackEvaluation(Comment comment) {
    final contentLength = comment.content.trim().length;
    
    // Simple length-based scoring
    double score = 3.0;
    if (contentLength > 100) score = 4.0;
    else if (contentLength > 50) score = 3.5;
    else if (contentLength < 10) score = 2.0;
    
    return CommentQuality.fromCriteria(
      commentId: comment.id!,
      relevance: score,
      clarity: score,
      constructiveness: score,
      tone: 4.0,
    );
  }

  /// Extract keywords from text
  static List<String> _extractKeywords(String text) {
    // Remove common stop words
    final stopWords = {
      'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
      'of', 'with', 'is', 'are', 'was', 'were', 'be', 'been', 'have', 'has',
      'had', 'do', 'does', 'did', 'will', 'would', 'could', 'should', 'may',
      'might', 'can', 'this', 'that', 'these', 'those', 'i', 'you', 'he',
      'she', 'it', 'we', 'they', 'what', 'which', 'who', 'when', 'where',
      'why', 'how'
    };
    
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 3 && !stopWords.contains(word))
        .toList();
  }

  /// Round score to 1 decimal place
  static double _roundScore(double score) {
    return (score * 10).round() / 10;
  }

  /// Get rating color based on score
  static String getRatingColor(double score) {
    if (score >= 4.5) return '#4CAF50'; // Green
    if (score >= 3.5) return '#2196F3'; // Blue
    if (score >= 2.5) return '#FF9800'; // Orange
    if (score >= 1.5) return '#FF5722'; // Deep Orange
    return '#9E9E9E'; // Grey
  }

  /// Get rating description
  static String getRatingDescription(double score) {
    if (score >= 4.5) return 'Excellent contribution! 🌟';
    if (score >= 3.5) return 'Good quality comment ✨';
    if (score >= 2.5) return 'Average contribution ⭐';
    if (score >= 1.5) return 'Needs improvement 💫';
    return 'Low quality ⚪';
  }
}
