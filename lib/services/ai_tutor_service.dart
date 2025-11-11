import 'dart:convert';
import 'package:http/http.dart' as http;

class AITutorService {
  // 🔑 Replace with a valid Google Cloud API key
  static const String _geminiApiKey = 'AIzaSyDPF2EBjLdnL7Ym2cvGDHPZkehGc-Yxa5o';

  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  // ✅ Switched to faster, less overloaded model
  static const String _modelName = 'gemini-2.5-flash';

  String get _generateEndpoint =>
      '$_baseUrl/models/$_modelName:generateContent?key=$_geminiApiKey';

  /// Ask a question with retry logic (3 retries by default)
  Future<Map<String, dynamic>> askQuestion({
    required String question,
    Map<String, String>? postContext,
    String language = 'en',
    List<Map<String, String>>? conversationHistory,
    int retries = 3,
    int delaySeconds = 2,
  }) async {
    for (int attempt = 0; attempt < retries; attempt++) {
      try {
        print('🤖 Processing question (attempt ${attempt + 1})...');
        final prompt = _buildPrompt(question, postContext, language, conversationHistory);

        final response = await http.post(
          Uri.parse(_generateEndpoint),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt}
                ]
              }
            ],
            'generationConfig': {
              'temperature': 0.7,
              'topK': 40,
              'topP': 0.95,
              'maxOutputTokens': 1024,
            },
          }),
        ).timeout(const Duration(seconds: 25));

        print('📥 Status: ${response.statusCode}');
        print('📄 Body: ${response.body}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final aiResponse = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
          if (aiResponse != null) {
            return {
              'success': true,
              'response': aiResponse.trim(),
              'language': language,
              'model': _modelName,
              'timestamp': DateTime.now().toIso8601String(),
            };
          }
        } else if (response.statusCode == 503) {
          // Model overloaded, will retry
          print('⚠️ Model overloaded, retrying...');
        } else {
          // Other errors
          print('❌ API returned status ${response.statusCode}');
        }
      } catch (e) {
        print('❌ Error: $e');
      }

      // Delay before next retry (exponential backoff)
      await Future.delayed(Duration(seconds: delaySeconds));
      delaySeconds *= 2;
    }

    // If all retries fail, return fallback
    return _getFallbackResponse(question, postContext, language);
  }

  String _buildPrompt(
      String question,
      Map<String, String>? postContext,
      String language,
      List<Map<String, String>>? conversationHistory) {
    final buffer = StringBuffer();
    buffer.writeln('You are an AI tutor.\nLanguage: $language\nQuestion: $question');
    if (postContext != null && postContext.isNotEmpty) {
      buffer.writeln('Context:');
      postContext.forEach((k, v) => buffer.writeln('$k: $v'));
    }
    if (conversationHistory != null && conversationHistory.isNotEmpty) {
      buffer.writeln('Previous conversation:');
      for (var msg in conversationHistory.take(5)) {
        buffer.writeln('${msg['role']}: ${msg['content']}');
      }
    }
    return buffer.toString();
  }

  Map<String, dynamic> _getFallbackResponse(
      String question, Map<String, String>? postContext, String language) {
    print('🔄 Using offline fallback...');
    return {
      'success': true,
      'response':
      "I'm offline or the model is overloaded. Try again later.",
      'language': language,
      'model': 'fallback',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
