import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/comment_model.dart';

/// AI Mentor Service - Provides intelligent hints and guidance for student questions
class AIMentorService {
  // TODO: Replace with your actual API key
  static const String _apiKey = 'AIzaSyDPF2EBjLdnL7Ym2cvGDHPZkehGc-Yxa5o';
  static const String _geminiEndpoint = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';
  
  // AI Mentor user ID (special system user)
  static const int aiMentorUserId = -1;
  static const String aiMentorName = 'AI Mentor';
  
  /// Generate mentor hint for a post
  static Future<String> generateHint({
    required String postTitle,
    required String postContent,
    String? category,
    bool regenerate = false,
  }) async {
    try {
      // For now, use intelligent mock hints
      // To use real AI, uncomment the API call below
      return _getMockHint(postTitle, postContent, category, regenerate);

      // REAL API CALL (uncomment when you have API key):
      // return await _callGeminiAPI(postTitle, postContent, category, regenerate);
      
    } catch (e) {
      print('❌ AI Mentor Error: $e');
      return _getFallbackHint();
    }
  }
  
  /// Check if a post needs AI mentor assistance
  static bool needsMentorHelp({
    required int commentCount,
    required DateTime postDate,
    int minuteThreshold = 2,
  }) {
    // No comments and post is older than threshold
    if (commentCount > 0) return false;
    
    final minutesSincePost = DateTime.now().difference(postDate).inMinutes;
    return minutesSincePost >= minuteThreshold;
  }
  
  /// Call Gemini API for real AI mentor hints
  static Future<String> _callGeminiAPI(
    String postTitle,
    String postContent,
    String? category,
    bool regenerate,
  ) async {
    final prompt = _buildMentorPrompt(postTitle, postContent, category, regenerate);
    
    final response = await http.post(
      Uri.parse('$_geminiEndpoint?key=$_apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [{
          'parts': [{'text': prompt}]
        }],
        'generationConfig': {
          'temperature': regenerate ? 0.9 : 0.7,
          'maxOutputTokens': 300,
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['candidates'][0]['content']['parts'][0]['text'] as String;
      return text.trim();
    } else {
      throw Exception('API call failed: ${response.statusCode}');
    }
  }
  
  /// Build prompt for AI mentor
  static String _buildMentorPrompt(
    String postTitle,
    String postContent,
    String? category,
    bool regenerate,
  ) {
    final categoryContext = category != null ? '\nCategory: $category' : '';
    final variation = regenerate ? '\nProvide a DIFFERENT approach or perspective than typical hints.' : '';
    
    return '''
You are a helpful and encouraging educational tutor/mentor. A student has posted a question that hasn't been answered yet.

Your role:
- Provide hints and guidance, NOT complete answers
- Ask guiding questions that help students think critically
- Break down complex problems into smaller steps
- Encourage independent thinking
- Be supportive and motivating

Student's Question:
Title: $postTitle
Content: $postContent$categoryContext$variation

Respond with:
1. A brief encouraging statement
2. 2-3 guiding hints or questions
3. Suggest a thinking approach or method

Keep your response concise (3-4 sentences max) and educational.
Use emojis sparingly for engagement (💡, 🤔, ✨).
''';
  }
  
  /// Intelligent mock hints (works without API key)
  static String _getMockHint(
    String postTitle,
    String postContent,
    String? category,
    bool regenerate,
  ) {
    final content = postContent.toLowerCase();
    final title = postTitle.toLowerCase();
    final combinedText = '$title $content';
    
    // First: Detect specific topic/technology for contextual hints
    final topicContext = _detectTopic(combinedText);
    
    // Then: Detect question type
    if (_isHowToQuestion(content, title)) {
      return _generateHowToHint(postTitle, postContent, topicContext, regenerate);
    } else if (_isWhyQuestion(content, title)) {
      return _generateWhyHint(postTitle, postContent, topicContext, regenerate);
    } else if (_isWhatQuestion(content, title)) {
      return _generateWhatHint(postTitle, postContent, topicContext, regenerate);
    } else if (_isErrorQuestion(content, title)) {
      return _generateErrorHint(postTitle, postContent, topicContext, regenerate);
    } else if (_isConceptQuestion(content, title)) {
      return _generateConceptHint(postTitle, postContent, topicContext, regenerate);
    } else {
      return _generateGenericHint(postTitle, postContent, topicContext, regenerate);
    }
  }
  
  /// Detect topic/technology from content
  static String _detectTopic(String text) {
    // Mobile Development
    if (text.contains('flutter') || text.contains('dart')) return 'Flutter/Dart';
    if (text.contains('android') || text.contains('kotlin')) return 'Android';
    if (text.contains('ios') || text.contains('swift')) return 'iOS';
    if (text.contains('react native')) return 'React Native';
    
    // Web Development
    if (text.contains('react') || text.contains('jsx')) return 'React';
    if (text.contains('vue') || text.contains('vuejs')) return 'Vue.js';
    if (text.contains('angular')) return 'Angular';
    if (text.contains('html') || text.contains('css')) return 'Web Design';
    if (text.contains('javascript') || text.contains('js')) return 'JavaScript';
    if (text.contains('typescript') || text.contains('ts')) return 'TypeScript';
    if (text.contains('node') || text.contains('express')) return 'Node.js';
    
    // Programming Languages
    if (text.contains('python')) return 'Python';
    if (text.contains('java') && !text.contains('javascript')) return 'Java';
    if (text.contains('c++') || text.contains('cpp')) return 'C++';
    if (text.contains('c#') || text.contains('csharp')) return 'C#';
    if (text.contains('php')) return 'PHP';
    if (text.contains('ruby')) return 'Ruby';
    if (text.contains('go') || text.contains('golang')) return 'Go';
    if (text.contains('rust')) return 'Rust';
    
    // Database
    if (text.contains('sql') || text.contains('database') || text.contains('mysql') || text.contains('postgresql')) return 'Database/SQL';
    if (text.contains('mongodb') || text.contains('nosql')) return 'NoSQL/MongoDB';
    if (text.contains('firebase')) return 'Firebase';
    
    // Algorithms & Data Structures
    if (text.contains('algorithm') || text.contains('sorting') || text.contains('searching')) return 'Algorithms';
    if (text.contains('data structure') || text.contains('array') || text.contains('linked list') || text.contains('tree') || text.contains('graph')) return 'Data Structures';
    
    // Other CS topics
    if (text.contains('api') || text.contains('rest') || text.contains('graphql')) return 'API Development';
    if (text.contains('git') || text.contains('github') || text.contains('version control')) return 'Git/Version Control';
    if (text.contains('docker') || text.contains('container')) return 'Docker/DevOps';
    if (text.contains('ui') || text.contains('ux') || text.contains('design')) return 'UI/UX Design';
    if (text.contains('test') || text.contains('unit test')) return 'Testing';
    
    return 'General Programming';
  }
  
  /// Generate "How to" hints
  static String _generateHowToHint(String title, String content, String topic, bool regenerate) {
    final topicHint = _getTopicSpecificHint(topic, 'how-to');
    
    final hints = regenerate ? [
      "💡 Great $topic question! $topicHint Try breaking this into smaller steps - what's the first action you need? Often the rest follows naturally!",
      "🤔 Interesting $topic challenge! Have you checked the official $topic documentation for examples? Real-world patterns often spark solutions for your specific case.",
      "✨ Good $topic thinking! List what you already know, then identify gaps. For $topic, this systematic approach reveals the exact resources you need next.",
    ] : [
      "💡 Great $topic question! $topicHint Let's break this into components. What's the core functionality you need first? Build from there!",
      "🤔 Good $topic question! Have you looked at $topic examples or tutorials? Understanding the pattern helps. Which specific part is blocking you?",
      "✨ Interesting $topic challenge! What's your end goal? In $topic, clearly defining the target often reveals the path forward.",
    ];
    
    return hints[DateTime.now().millisecond % hints.length];
  }
  
  /// Generate "Why" hints
  static String _generateWhyHint(String title, String content, String topic, bool regenerate) {
    final topicHint = _getTopicSpecificHint(topic, 'why');
    
    final hints = regenerate ? [
      "💡 Excellent $topic question! $topicHint To understand 'why', consider what would happen with a different approach. The comparison reveals the reasoning!",
      "🤔 Deep $topic question! Every $topic design decision solves a problem. What challenges or limitations is this addressing? That's your 'why'!",
      "✨ Great $topic curiosity! Research how this evolved in $topic. Historical context often reveals the 'why' behind current best practices.",
    ] : [
      "💡 Excellent $topic question! $topicHint Think about the problem being solved. What would happen without this? That reveals the purpose!",
      "🤔 Great $topic curiosity! Identify what limitation this addresses. In $topic, every pattern has reasoning. What issue does this prevent?",
      "✨ Good $topic thinking! Consider the trade-offs. Why might $topic choose this over alternatives? What benefits does it provide?",
    ];
    
    return hints[DateTime.now().millisecond % hints.length];
  }
  
  /// Generate "What" hints
  static String _generateWhatHint(String title, String content, String topic, bool regenerate) {
    final topicHint = _getTopicSpecificHint(topic, 'what');
    
    final hints = regenerate ? [
      "💡 Good $topic question! $topicHint Try explaining it in your own words first. Then check $topic documentation to verify your understanding!",
      "🤔 Great $topic inquiry! Look at where this is used in $topic. Context gives powerful clues about what something is or does.",
      "✨ Interesting $topic question! Break it into core components. What are the key $topic characteristics? Understanding parts reveals the whole!",
    ] : [
      "💡 Great $topic question! $topicHint Check the official $topic documentation first, then rephrase it yourself. That's how understanding builds!",
      "🤔 Good $topic inquiry! Consider the context - where is this used in $topic? Understanding 'why' often clarifies the 'what'.",
      "✨ Interesting $topic question! Compare it with similar $topic concepts you know. What's different? Analogies accelerate understanding!",
    ];
    
    return hints[DateTime.now().millisecond % hints.length];
  }
  
  /// Generate error-related hints
  static String _generateErrorHint(String title, String content, String topic, bool regenerate) {
    final topicHint = _getTopicSpecificHint(topic, 'error');
    
    final hints = regenerate ? [
      "💡 $topic errors teach us! $topicHint Read the error carefully - what specific part is it complaining about? $topic errors are usually literal!",
      "🤔 $topic debugging tip: Comment out recent changes one by one. When the error vanishes, you've found it! Then understand why it broke in $topic.",
      "✨ Good approach! Search the exact $topic error message - others have likely hit this. Look for patterns in $topic-specific solutions.",
    ] : [
      "💡 $topic errors are opportunities! $topicHint What line is indicated? What error type? These $topic clues point you to the solution!",
      "🤔 Good $topic question! Isolate the problem. What changed before this $topic error appeared? Check syntax against $topic conventions!",
      "✨ $topic debugging: Use debugging tools (print/log statements) to check values. This reveals where $topic logic breaks. What have you tried?",
    ];
    
    return hints[DateTime.now().millisecond % hints.length];
  }
  
  /// Generate concept understanding hints
  static String _generateConceptHint(String title, String content, String topic, bool regenerate) {
    final topicHint = _getTopicSpecificHint(topic, 'concept');
    
    final hints = regenerate ? [
      "💡 Deep $topic learning! $topicHint Try teaching this $topic concept to someone. If you can explain it clearly, you've truly mastered it!",
      "🤔 Great $topic approach! Create a simple $topic example from scratch. Building something yourself cements understanding better than reading!",
      "✨ Excellent $topic question! Draw it out! Visual diagrams of $topic concepts make abstract ideas concrete and easier to grasp.",
    ] : [
      "💡 Great $topic learning question! $topicHint Explain this $topic concept out loud. Teaching yourself is the path to understanding!",
      "🤔 Excellent $topic approach! Break this into pieces. What's the simplest $topic example? Start small, then build complexity gradually.",
      "✨ Good $topic thinking! Create a practical $topic project using this concept. Hands-on practice clarifies theory better than anything!",
    ];
    
    return hints[DateTime.now().millisecond % hints.length];
  }
  
  /// Generate generic helpful hints
  static String _generateGenericHint(String title, String content, String topic, bool regenerate) {
    final topicHint = _getTopicSpecificHint(topic, 'generic');
    
    final hints = regenerate ? [
      "💡 I'm here to guide your $topic journey! $topicHint What $topic resources have you explored? Revisiting with fresh eyes often reveals insights!",
      "🤔 Great $topic question! Let's be systematic. What $topic concepts do you know? What's unclear? Identifying the gap is half the solution!",
      "✨ Excellent $topic question! Try simplifying - explain it like teaching a beginner. This often reveals the core $topic issue and solutions!",
    ] : [
      "💡 Great $topic question! $topicHint What have you tried? Understanding what hasn't worked guides us to what will in $topic!",
      "🤔 Good $topic thinking! List what you know vs. don't know. Break this into smaller $topic questions. One piece at a time!",
      "✨ Interesting $topic topic! Check official $topic documentation or tutorials. Examples often provide the 'aha!' moment. What part confuses you most?",
    ];
    
    return hints[DateTime.now().millisecond % hints.length];
  }
  
  /// Get topic-specific contextual hint
  static String _getTopicSpecificHint(String topic, String questionType) {
    final hints = {
      'Flutter/Dart': {
        'how-to': 'In Flutter, check the widget tree structure and state management.',
        'why': 'Flutter\'s reactive framework has specific reasons for its patterns.',
        'what': 'Flutter widgets are the building blocks - understand their lifecycle.',
        'error': 'Flutter errors often point to widget build issues or null safety.',
        'concept': 'Flutter concepts are best learned by building small widget examples.',
        'generic': 'Flutter documentation at flutter.dev is your best friend.',
      },
      'React': {
        'how-to': 'In React, think about component structure and state flow.',
        'why': 'React\'s virtual DOM and one-way data flow drive its design decisions.',
        'what': 'React components are functions or classes that return JSX.',
        'error': 'React errors often relate to props, state, or hook rules.',
        'concept': 'React concepts click when you build interactive components.',
        'generic': 'Check React.dev for official guides and patterns.',
      },
      'Python': {
        'how-to': 'Python favors readability - check the syntax and common patterns.',
        'why': 'Python\'s philosophy emphasizes clarity and simplicity.',
        'what': 'Python types and structures are dynamic - focus on behavior.',
        'error': 'Python errors are descriptive - read the traceback carefully.',
        'concept': 'Python concepts are best learned interactively in REPL.',
        'generic': 'Python docs and PEP guidelines explain best practices.',
      },
      'JavaScript': {
        'how-to': 'JavaScript is event-driven - think about async operations.',
        'why': 'JavaScript\'s flexibility and browser origins shape its behavior.',
        'what': 'JavaScript types are dynamic - understand type coercion.',
        'error': 'JavaScript errors often involve undefined, null, or scope issues.',
        'concept': 'JavaScript concepts need practice with callbacks and promises.',
        'generic': 'MDN Web Docs provide comprehensive JavaScript references.',
      },
      'Database/SQL': {
        'how-to': 'SQL queries follow SELECT-FROM-WHERE logic structure.',
        'why': 'Relational databases use normalization for data integrity.',
        'what': 'SQL operates on tables with rows (records) and columns (fields).',
        'error': 'SQL errors often involve syntax or constraint violations.',
        'concept': 'SQL concepts are visual - draw table relationships.',
        'generic': 'Practice SQL queries on sample databases to learn.',
      },
      'Algorithms': {
        'how-to': 'Algorithms need step-by-step pseudocode before coding.',
        'why': 'Algorithm efficiency matters for performance at scale.',
        'what': 'Algorithms are step-by-step procedures to solve problems.',
        'error': 'Algorithm bugs often involve edge cases or loop conditions.',
        'concept': 'Algorithm concepts need visualization - draw them out.',
        'generic': 'Practice algorithms on paper before implementing.',
      },
      'Data Structures': {
        'how-to': 'Data structures require understanding operations and complexity.',
        'why': 'Each data structure optimizes different operation types.',
        'what': 'Data structures organize data for efficient access patterns.',
        'error': 'Data structure errors often involve index bounds or null references.',
        'concept': 'Data structure concepts need visual diagrams to grasp.',
        'generic': 'Implement basic data structures yourself to learn deeply.',
      },
    };
    
    // Get topic-specific hint, or use general programming hint
    final topicHints = hints[topic];
    if (topicHints != null && topicHints.containsKey(questionType)) {
      return topicHints[questionType]!;
    }
    
    // Default hints for unmapped topics
    return {
      'how-to': 'Start with documentation and examples.',
      'why': 'Consider the problem being solved.',
      'what': 'Check official definitions first.',
      'error': 'Read error messages carefully.',
      'concept': 'Build examples to learn.',
      'generic': 'Break it down into smaller pieces.',
    }[questionType] ?? 'Think systematically.';
  }
  
  /// Fallback hint when everything fails
  static String _getFallbackHint() {
    return "💡 Great question! I'm here to help guide you. Try breaking down the problem into smaller parts and tackle each one individually. What specific aspect would you like to explore first?";
  }
  
  /// Question type detection helpers
  static bool _isHowToQuestion(String content, String title) {
    return content.contains('how to') || 
           content.contains('how can') || 
           content.contains('how do') ||
           title.contains('how to') ||
           title.contains('how can') ||
           title.contains('how do');
  }
  
  static bool _isWhyQuestion(String content, String title) {
    return content.contains('why') || title.contains('why');
  }
  
  static bool _isWhatQuestion(String content, String title) {
    return content.contains('what is') || 
           content.contains('what are') || 
           content.contains('what does') ||
           title.contains('what is') ||
           title.contains('what are');
  }
  
  static bool _isErrorQuestion(String content, String title) {
    return content.contains('error') || 
           content.contains('exception') || 
           content.contains('bug') ||
           content.contains('not working') ||
           content.contains('doesn\'t work') ||
           title.contains('error') ||
           title.contains('bug');
  }
  
  static bool _isConceptQuestion(String content, String title) {
    return content.contains('understand') || 
           content.contains('concept') || 
           content.contains('explain') ||
           content.contains('difference between') ||
           title.contains('understand') ||
           title.contains('concept');
  }
  
  /// Generate resource links based on topic keywords
  static List<String> suggestResources(String postContent, String? category) {
    final resources = <String>[];
    final content = postContent.toLowerCase();
    
    // Programming topics
    if (content.contains('flutter') || content.contains('dart')) {
      resources.add('📚 Flutter Documentation: flutter.dev/docs');
      resources.add('🎯 Dart Language Tour: dart.dev/guides/language');
    }
    
    if (content.contains('algorithm') || content.contains('data structure')) {
      resources.add('📘 Visualgo: visualgo.net (Algorithm Visualizations)');
      resources.add('💻 GeeksforGeeks: geeksforgeeks.org');
    }
    
    if (content.contains('javascript') || content.contains('react')) {
      resources.add('📖 MDN Web Docs: developer.mozilla.org');
      resources.add('⚛️ React Docs: react.dev');
    }
    
    if (content.contains('python')) {
      resources.add('🐍 Python Docs: docs.python.org');
      resources.add('📗 Real Python: realpython.com');
    }
    
    // Generic learning resources
    if (resources.isEmpty) {
      resources.add('💡 Stack Overflow: stackoverflow.com');
      resources.add('📚 W3Schools: w3schools.com');
    }
    
    return resources.take(2).toList();
  }
}
