import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/debate_model.dart';
import '../models/comment_model.dart';
import 'ai_comment_rating_service.dart';

class AIDebateService {
  // TODO: Replace with your actual API key or use environment variables
  static const String _apiKey = 'AIzaSyDPF2EBjLdnL7Ym2cvGDHPZkehGc-Yxa5o';
  static const String _geminiEndpoint = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';

  /// Analyze comments and generate debate structure
  static Future<DebateAnalysis> analyzeDebate({
    required String postId,
    required String postContent,
    required List<Comment> comments,
    required Map<int, String> userNames,
  }) async {
    try {
      // If there are fewer than 3 comments, return a simple analysis
      if (comments.length < 3) {
        return _createSimpleAnalysis(postId, comments, userNames);
      }

      // Build the prompt for AI
      final prompt = _buildDebatePrompt(postContent, comments, userNames);

      // For now, return mock data (you can integrate with Gemini API)
      // To use real AI, uncomment the API call below
      return await _getMockDebateAnalysis(postId, comments, userNames);

      // REAL API CALL (uncomment when you have API key):
      // return await _callGeminiAPI(prompt, postId, comments, userNames);
      
    } catch (e) {
      print('❌ AI Debate Analysis Error: $e');
      return _createSimpleAnalysis(postId, comments, userNames);
    }
  }

  /// Build prompt for AI analysis
  static String _buildDebatePrompt(
    String postContent,
    List<Comment> comments,
    Map<int, String> userNames,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('Analyze this educational discussion and create a debate structure:');
    buffer.writeln('\nPOST TOPIC:');
    buffer.writeln(postContent);
    buffer.writeln('\nCOMMENTS:');
    
    for (var i = 0; i < comments.length; i++) {
      final comment = comments[i];
      final userName = userNames[comment.userId] ?? 'User ${comment.userId}';
      buffer.writeln('${i + 1}. $userName: ${comment.content}');
    }

    buffer.writeln('\nPlease analyze and provide:');
    buffer.writeln('1. Classify each comment as "for", "against", or "neutral" regarding the topic');
    buffer.writeln('2. Rate each comment quality (0-10) based on reasoning depth');
    buffer.writeln('3. Identify the top contributor with the best reasoning');
    buffer.writeln('4. Provide a 2-sentence summary of the discussion');
    buffer.writeln('5. Generate a verdict or conclusion about what the group thinks');
    buffer.writeln('\nReturn as JSON with structure: {forArguments: [], againstArguments: [], neutralArguments: [], summary: "", verdict: "", topContributor: {}}');

    return buffer.toString();
  }

  /// Call Gemini API (implement when you have API key)
  static Future<DebateAnalysis> _callGeminiAPI(
    String prompt,
    String postId,
    List<Comment> comments,
    Map<int, String> userNames,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_geminiEndpoint?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{
            'parts': [{'text': prompt}]
          }]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse = data['candidates'][0]['content']['parts'][0]['text'];
        
        // Parse AI response and create DebateAnalysis
        final analysisJson = jsonDecode(aiResponse);
        return DebateAnalysis.fromJson({
          ...analysisJson,
          'postId': postId,
          'analyzedAt': DateTime.now().toIso8601String(),
        });
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Gemini API Error: $e');
      return _getMockDebateAnalysis(postId, comments, userNames);
    }
  }

  /// Create mock debate analysis (intelligent fallback)
  static Future<DebateAnalysis> _getMockDebateAnalysis(
    String postId,
    List<Comment> comments,
    Map<int, String> userNames,
  ) async {
    // Simulate AI processing
    await Future.delayed(const Duration(milliseconds: 500));

    // Intelligent classification based on keywords
    final forArgs = <DebateArgument>[];
    final againstArgs = <DebateArgument>[];
    final neutralArgs = <DebateArgument>[];

    for (var comment in comments) {
      final content = comment.content.toLowerCase();
      final userName = userNames[comment.userId] ?? 'User ${comment.userId}';
      
      // Use real comment quality rating if available, otherwise calculate
      double quality;
      if (comment.qualityRating != null) {
        quality = comment.qualityRating!;
      } else {
        quality = _calculateQuality(comment.content);
      }
      
      // Simple keyword-based classification
      String stance = 'neutral';
      String reasoning = 'Provides perspective on the topic';

      if (_containsPositiveKeywords(content)) {
        stance = 'for';
        reasoning = 'Supports the topic with clear reasoning';
      } else if (_containsNegativeKeywords(content)) {
        stance = 'against';
        reasoning = 'Presents counterarguments and concerns';
      } else {
        reasoning = 'Offers balanced viewpoint';
      }

      final argument = DebateArgument(
        commentId: comment.id ?? 0,
        userName: userName,
        content: comment.content,
        stance: stance,
        qualityScore: quality,
        reasoning: reasoning,
      );

      if (stance == 'for') {
        forArgs.add(argument);
      } else if (stance == 'against') {
        againstArgs.add(argument);
      } else {
        neutralArgs.add(argument);
      }
    }

    // Find top contributor
    final allArgs = [...forArgs, ...againstArgs, ...neutralArgs];
    allArgs.sort((a, b) => b.qualityScore.compareTo(a.qualityScore));
    
    DebateContributor? topContributor;
    if (allArgs.isNotEmpty) {
      final topArg = allArgs.first;
      topContributor = DebateContributor(
        userId: topArg.commentId,
        userName: topArg.userName,
        contributionScore: topArg.qualityScore,
        contributionReason: 'Most thoughtful and well-reasoned contribution',
      );
    }

    // Generate summary
    final summary = _generateSummary(forArgs.length, againstArgs.length, neutralArgs.length, comments.length);
    
    // Generate verdict
    final verdict = _generateVerdict(forArgs.length, againstArgs.length, neutralArgs.length);

    return DebateAnalysis(
      postId: postId,
      forArguments: forArgs,
      againstArguments: againstArgs,
      neutralArguments: neutralArgs,
      summary: summary,
      verdict: verdict,
      topContributor: topContributor,
      analyzedAt: DateTime.now(),
    );
  }

  /// Simple analysis for posts with few comments
  static DebateAnalysis _createSimpleAnalysis(
    String postId,
    List<Comment> comments,
    Map<int, String> userNames,
  ) {
    final neutralArgs = comments.map((comment) {
      // Use real comment quality rating if available
      final quality = comment.qualityRating ?? _calculateQuality(comment.content);
      
      return DebateArgument(
        commentId: comment.id ?? 0,
        userName: userNames[comment.userId] ?? 'User ${comment.userId}',
        content: comment.content,
        stance: 'neutral',
        qualityScore: quality,
        reasoning: 'Contributes to the discussion',
      );
    }).toList();

    return DebateAnalysis(
      postId: postId,
      forArguments: [],
      againstArguments: [],
      neutralArguments: neutralArgs,
      summary: 'Discussion is in early stages with ${comments.length} comment(s). More participation needed for debate analysis.',
      verdict: 'The conversation is just beginning. Keep discussing!',
      topContributor: null,
      analyzedAt: DateTime.now(),
    );
  }

  // Helper methods
  static bool _containsPositiveKeywords(String text) {
    final positive = ['agree', 'yes', 'good', 'great', 'right', 'correct', 'absolutely', 
                      'definitely', 'support', 'love', 'excellent', 'perfect', 'true'];
    return positive.any((word) => text.contains(word));
  }

  static bool _containsNegativeKeywords(String text) {
    final negative = ['disagree', 'no', 'wrong', 'incorrect', 'bad', 'against', 
                      'shouldn\'t', 'can\'t', 'won\'t', 'never', 'doubt', 'concern'];
    return negative.any((word) => text.contains(word));
  }

  static double _calculateQuality(String content) {
    double score = 5.0;
    
    // Longer, more detailed comments score higher
    if (content.length > 100) score += 2.0;
    if (content.length > 200) score += 1.0;
    
    // Questions add depth
    if (content.contains('?')) score += 0.5;
    
    // Multiple sentences suggest more thought
    if (content.split('.').length > 2) score += 1.0;
    
    return score.clamp(0.0, 10.0);
  }

  static String _generateSummary(int forCount, int againstCount, int neutralCount, int totalCount) {
    if (forCount > againstCount && forCount > neutralCount) {
      return 'The discussion shows strong support with $forCount supportive arguments out of $totalCount comments. The majority agrees with the topic.';
    } else if (againstCount > forCount && againstCount > neutralCount) {
      return 'The discussion reveals significant concerns with $againstCount critical arguments out of $totalCount comments. There\'s notable opposition.';
    } else {
      return 'The discussion presents balanced perspectives with diverse viewpoints from $totalCount participants. No clear consensus yet.';
    }
  }

  static String _generateVerdict(int forCount, int againstCount, int neutralCount) {
    if (forCount > againstCount * 2) {
      return '🎯 The class strongly agrees with this perspective!';
    } else if (againstCount > forCount * 2) {
      return '⚠️ The class raises significant concerns about this topic.';
    } else if (forCount > againstCount) {
      return '👍 The class leans towards agreement with minor reservations.';
    } else if (againstCount > forCount) {
      return '🤔 The class has concerns but remains open to discussion.';
    } else {
      return '⚖️ The class is evenly divided - healthy debate in progress!';
    }
  }
}
