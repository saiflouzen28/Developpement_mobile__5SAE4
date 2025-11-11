import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'constants.dart';

/// Stores the last raw AI model output (for debugging/UI). May be null.
String? lastAiRawOutput;

/// Generate multiple-choice questions from an AI model.
Future<List<Map<String, dynamic>>> generateQuestionsFromAi({
  required String topic,
  required String description,
  required int totalQuestions,
  required String difficulty,
}) async {
  // Fallback mock
  List<Map<String, dynamic>> _mock() {
    final List<Map<String, dynamic>> mock = [];
    for (var i = 1; i <= totalQuestions; i++) {
      mock.add({
        'question_text': 'Question $i about $topic',
        'option_a': 'Correct answer for question $i',
        'option_b': 'Plausible distractor B for question $i',
        'option_c': 'Plausible distractor C for question $i',
        'option_d': 'Plausible distractor D for question $i',
        'correct_option': 'A',
      });
    }
    return mock;
  }

  // Parse plain text output into structured questions
  List<Map<String, dynamic>> _parseTextOutput(String output) {
    final List<Map<String, dynamic>> parsed = [];
    final normalized = output.replaceAll('\r', '').trim();
    final regex = RegExp(r'(?mi)(?:^|\n)\s*(?:Question\s*\d+[:.)]?|\d+[:.)])');
    final matches = regex.allMatches(normalized).toList();
    final blocks = <String>[];
    if (matches.isNotEmpty) {
      int last = 0;
      for (final m in matches) {
        if (m.start > last) blocks.add(normalized.substring(last, m.start));
        last = m.start;
      }
      blocks.add(normalized.substring(last));
      if (blocks.isNotEmpty && blocks.first.trim().isEmpty) blocks.removeAt(0);
    } else {
      blocks.addAll(normalized.split('\n\n'));
    }

    for (final blk in blocks) {
      final lines =
      blk.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      if (lines.isEmpty) continue;
      var q = lines.first;
      q = q.replaceFirst(
          RegExp(r'^(?:Question\s*\d+[:.)]?|\d+[:.)]?)', caseSensitive: false),
          '').trim();

      String a = '', b = '', c = '', d = '';
      String correct = '';
      for (final line in lines.skip(1)) {
        final m = RegExp(r'^([A-Da-d])[\)\.:\-\s]+(.+)$').firstMatch(line);
        if (m != null) {
          final label = m.group(1)!.toUpperCase();
          final text = m.group(2)!.trim();
          if (label == 'A') a = text;
          if (label == 'B') b = text;
          if (label == 'C') c = text;
          if (label == 'D') d = text;
          continue;
        }
        final ans =
        RegExp(r'(?i)^(?:Answer|Correct)[:\s]+([A-Da-d])\b').firstMatch(line);
        if (ans != null) correct = ans.group(1)!.toUpperCase();
      }

      if (a.isEmpty && lines.length >= 5) {
        a = lines.length > 1 ? lines[1] : '';
        b = lines.length > 2 ? lines[2] : '';
        c = lines.length > 3 ? lines[3] : '';
        d = lines.length > 4 ? lines[4] : '';
      }

      if (q.isNotEmpty) {
        parsed.add({
          'question_text': q,
          'option_a': a.isEmpty ? 'Option A' : a,
          'option_b': b.isEmpty ? 'Option B' : b,
          'option_c': c.isEmpty ? 'Option C' : c,
          'option_d': d.isEmpty ? 'Option D' : d,
          'correct_option': correct.isEmpty ? 'A' : correct,
        });
      }
    }

    return parsed;
  }

  // Use Google Gemini API directly
  const kAiApiKey ='AIzaSyDPF2EBjLdnL7Ym2cvGDHPZkehGc-Yxa5o' ;

  if (kAiApiKey.isNotEmpty && kAiApiKey.startsWith('AIza')) {
    const int maxAttempts = 2;
    http.Response? resp;
    Exception? lastError;

    // Try multiple model identifiers that might be available
    final modelsToTry = [
      'gemini-1.5-flash',  // Latest flash model
      'gemini-1.5-pro',    // Latest pro model  
      'gemini-pro',        // Standard model
      'models/gemini-pro', // Fully qualified path
    ];

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      for (final model in modelsToTry) {
        try {
          const geminiApiKey = 'AIzaSyDPF2EBjLdnL7Ym2cvGDHPZkehGc-Yxa5o' ;
          final url = Uri.parse(
            "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=" + geminiApiKey,
          );
          
          print('AI: trying model: $model (attempt $attempt/$maxAttempts)');

        final prompt = '''Generate EXACTLY $totalQuestions multiple-choice questions about: $topic
Description: $description
Difficulty: $difficulty

Return ONLY valid JSON in this exact format (no markdown, no extra text):
{
  "questions": [
    {
      "question_text": "Your question here?",
      "options": ["Option A", "Option B", "Option C", "Option D"],
      "correct_option": "A"
    }
  ]
}''';

        final body = {
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 4096,  // Increased to ensure we get complete JSON
            'stopSequences': [],
          }
        };

          resp = await http
              .post(url, headers: {'Content-Type': 'application/json'}, body: json.encode(body))
              .timeout(const Duration(seconds: 30),
              onTimeout: () => throw TimeoutException('Request timed out'));

          print('AI: received response with status ${resp.statusCode}');
          
          if (resp.statusCode >= 200 && resp.statusCode < 300) {
            print('AI: ✅ SUCCESS with model: $model');
            break; // Exit inner loop
          } else {
            print('AI: ❌ Model $model failed with status ${resp.statusCode}');
            lastError = Exception('HTTP ${resp.statusCode}: ${resp.body}');
          }
        } catch (e) {
          print('AI: ❌ Model $model error: $e');
          lastError = e is Exception ? e : Exception(e.toString());
        }
      }
      
      // If we got a successful response, break outer loop
      if (resp != null && resp.statusCode >= 200 && resp.statusCode < 300) break;
      
      // Wait before retry
      if (attempt < maxAttempts) {
        print('AI: waiting before retry...');
        await Future.delayed(Duration(seconds: 2));
      }
    }

    if (resp != null && resp.statusCode >= 200 && resp.statusCode < 300) {
      lastAiRawOutput = resp.body;
      print('AI: parsing response body (${resp.body.length} chars)');
      
      final decoded = json.decode(resp.body);
      String output = '';

      if (decoded is Map && decoded['candidates'] is List && decoded['candidates'].isNotEmpty) {
        print('AI: found ${decoded['candidates'].length} candidate(s)');
        final candidate = decoded['candidates'][0];
        
        if (candidate is Map && candidate['content'] != null) {
          final content = candidate['content'];
          print('AI: content type: ${content.runtimeType}, keys: ${content is Map ? content.keys : 'N/A'}');
          
          // Handle different content structures
          if (content is Map && content['parts'] is List && content['parts'].isNotEmpty) {
            // Standard nested structure: content.parts[0].text
            output = content['parts'][0]['text']?.toString() ?? '';
            print('AI: extracted from content.parts[0].text');
          } else if (content is String) {
            // Direct string content
            output = content;
            print('AI: extracted from content (string)');
          } else if (content is List && content.isNotEmpty) {
            // Content is directly a list of parts
            output = content[0]['text']?.toString() ?? '';
            print('AI: extracted from content[0].text (list)');
          } else {
            print('AI: ❌ unexpected content structure');
          }
          
          if (output.isNotEmpty) {
            print('AI: extracted text (${output.length} chars)');
            print('AI: text preview: ${output.substring(0, output.length > 200 ? 200 : output.length)}...');
          }
        } else {
          print('AI: ❌ candidate missing content. Keys: ${candidate is Map ? candidate.keys : 'N/A'}');
        }
      } else {
        print('AI: ❌ no candidates in response');
      }

      // Try parse JSON (extract JSON if wrapped in markdown or text)
      try {
        print('AI: attempting to parse as JSON...');
        
        // Extract JSON from potential markdown code blocks or surrounding text
        String jsonStr = output;
        
        // Remove markdown code fences if present
        jsonStr = jsonStr.replaceAll(RegExp(r'```json\s*'), '').replaceAll(RegExp(r'```\s*$'), '');
        
        // Find the first { and last } to extract just the JSON part
        final firstBrace = jsonStr.indexOf('{');
        final lastBrace = jsonStr.lastIndexOf('}');
        
        if (firstBrace >= 0 && lastBrace > firstBrace) {
          jsonStr = jsonStr.substring(firstBrace, lastBrace + 1);
          print('AI: extracted JSON substring (${jsonStr.length} chars)');
        }
        
        dynamic parsed;
        try {
          parsed = json.decode(jsonStr);
          print('AI: JSON parsed successfully');
        } catch (e) {
          // Try to fix incomplete JSON by finding last complete question
          print('AI: attempting to repair incomplete JSON...');
          
          // Find the last complete question object
          final lastCompleteQuestion = jsonStr.lastIndexOf('}', jsonStr.length - 10);
          if (lastCompleteQuestion > 0) {
            // Try to close the array and object properly
            String repairedJson = jsonStr.substring(0, lastCompleteQuestion + 1) + ']}';
            try {
              parsed = json.decode(repairedJson);
              print('AI: ✅ repaired JSON successfully');
            } catch (e2) {
              throw e; // Throw original error
            }
          } else {
            throw e;
          }
        }
        
        final rawQuestions =
        parsed is Map && parsed['questions'] != null ? parsed['questions'] : parsed;
        
        if (rawQuestions is List) {
          print('AI: found ${rawQuestions.length} questions in JSON');
          final out = <Map<String, dynamic>>[];
          for (final q in rawQuestions) {
            if (q is Map) {
              final optionsRaw = q['options'] ?? q['choices'] ?? [];
              final options = optionsRaw is List
                  ? optionsRaw.map((e) => e.toString()).toList()
                  : <String>[];
              out.add({
                'question_text': (q['question_text'] ?? q['question'] ?? '').toString(),
                'option_a': options.length > 0 ? options[0] : '',
                'option_b': options.length > 1 ? options[1] : '',
                'option_c': options.length > 2 ? options[2] : '',
                'option_d': options.length > 3 ? options[3] : '',
                'correct_option': (q['correct_option'] ?? 'A').toString(),
              });
            }
          }
          if (out.isNotEmpty) {
            print('AI: ✅ returning ${out.length} parsed questions');
            return out;
          } else {
            print('AI: ❌ parsed 0 questions from JSON');
          }
        } else {
          print('AI: ❌ rawQuestions is not a List');
        }
      } catch (e) {
        print('AI: ❌ JSON parse failed: $e');
        print('AI: attempting plain-text parsing...');
        final parsed = _parseTextOutput(output);
        if (parsed.isNotEmpty) {
          print('AI: ✅ text parser returned ${parsed.length} questions');
          return parsed;
        } else {
          print('AI: ❌ text parser returned 0 questions');
        }
      }
    } else {
      final errorMsg = lastError.toString();
      print('AI: all API attempts failed. Error: $errorMsg');
      
      // Provide helpful troubleshooting message for 404 errors
      if (errorMsg.contains('404') || errorMsg.contains('NOT_FOUND')) {
        throw Exception('''
❌ API Key Error: The Generative Language API is not accessible.

Possible causes:
1. API not enabled - Visit: https://console.cloud.google.com/apis/library/generativelanguage.googleapis.com
2. Billing not enabled on your Google Cloud project
3. API key restrictions blocking the API

Your API key: ${kAiApiKey.substring(0, 15)}...

💡 Alternative Solution:
Set up a custom AI endpoint by configuring kAiApiEndpoint in constants.dart
''');
      }
      
      throw Exception('Google API failed: ${lastError ?? "Unknown error"}');
    }
  }

  throw Exception('AI generation failed. Last raw output: ${lastAiRawOutput ?? "<none>"}');
}
