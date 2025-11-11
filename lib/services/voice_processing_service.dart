import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/voice_comment_model.dart';

/// Voice Processing Service - Handles speech-to-text, keyword extraction, and tone analysis
class VoiceProcessingService {
  // TODO: Replace with your actual API keys
  static const String _speechApiKey = '1a3352fdaf8a4ccbb1961df1c4c43fc8';
  static const String _geminiApiKey = 'AIzaSyDPF2EBjLdnL7Ym2cvGDHPZkehGc-Yxa5o';
  
  /// Transcribe audio file to text
  /// Using AssemblyAI (Free tier: 5 hours/month, no credit card needed)
  static Future<String> transcribeAudio(String audioFilePath) async {
    try {
      // Use AssemblyAI if API key is set
      if (_speechApiKey != 'YOUR_GOOGLE_SPEECH_API_KEY' && _speechApiKey.isNotEmpty) {
        print('🎤 Using AssemblyAI for transcription...');
        return await _transcribeWithAssemblyAI(audioFilePath);
      }
      
      // MOCK TRANSCRIPTION (using until you add API key)
      await Future.delayed(const Duration(seconds: 2));
      return '[Voice recorded - Add free AssemblyAI API key to transcribe what you say. Sign up at assemblyai.com (no credit card needed)]';
      
    } catch (e) {
      print('❌ Transcription Error: $e');
      return '[Transcription unavailable]';
    }
  }
  
  /// Extract keywords and tags from transcription
  static Future<List<String>> extractKeywords(String transcription) async {
    try {
      final text = transcription.toLowerCase();
      final keywords = <String>[];
      
      // Technology keywords
      final techKeywords = {
        'flutter': ['flutter', 'dart', 'widget', 'stateful', 'stateless'],
        'react': ['react', 'jsx', 'component', 'hooks', 'usestate', 'useeffect'],
        'python': ['python', 'django', 'flask', 'pandas', 'numpy'],
        'javascript': ['javascript', 'js', 'node', 'express', 'async', 'promise'],
        'java': ['java', 'spring', 'maven', 'gradle', 'jvm'],
        'database': ['sql', 'database', 'mysql', 'postgresql', 'mongodb', 'nosql'],
        'algorithm': ['algorithm', 'sorting', 'searching', 'complexity', 'big-o'],
        'datastructure': ['array', 'list', 'tree', 'graph', 'stack', 'queue', 'hashmap'],
        'web': ['html', 'css', 'frontend', 'backend', 'api', 'rest', 'http'],
        'mobile': ['android', 'ios', 'mobile', 'app'],
        'git': ['git', 'github', 'commit', 'branch', 'merge'],
        'testing': ['test', 'testing', 'unit test', 'integration', 'tdd'],
        'design': ['ui', 'ux', 'design', 'interface', 'user experience'],
        'security': ['security', 'authentication', 'authorization', 'encryption'],
        'cloud': ['cloud', 'aws', 'azure', 'gcp', 'docker', 'kubernetes'],
      };
      
      // Check for technology keywords
      for (final entry in techKeywords.entries) {
        for (final keyword in entry.value) {
          if (text.contains(keyword)) {
            keywords.add('#${entry.key}');
            break;
          }
        }
      }
      
      // Common programming concepts
      final concepts = [
        'oop', 'functional', 'async', 'sync', 'error', 'bug', 'debug',
        'performance', 'optimization', 'refactor', 'clean-code',
        'architecture', 'pattern', 'solid', 'dependency-injection',
      ];
      
      for (final concept in concepts) {
        if (text.contains(concept)) {
          keywords.add('#$concept');
        }
      }
      
      // Question indicators
      if (text.contains('how') || text.contains('?')) keywords.add('#question');
      if (text.contains('help') || text.contains('stuck')) keywords.add('#help-needed');
      if (text.contains('solution') || text.contains('solved')) keywords.add('#solution');
      if (text.contains('error') || text.contains('exception')) keywords.add('#error');
      
      // Remove duplicates and limit
      return keywords.toSet().take(6).toList();
      
    } catch (e) {
      print('❌ Keyword Extraction Error: $e');
      return [];
    }
  }
  
  /// Analyze tone/sentiment of transcription
  static Future<String> analyzeTone(String transcription) async {
    try {
      final text = transcription.toLowerCase();
      
      // Positive indicators
      final positiveWords = [
        'great', 'excellent', 'thanks', 'thank you', 'awesome', 'perfect',
        'love', 'amazing', 'helpful', 'works', 'solved', 'success',
      ];
      
      // Negative indicators
      final negativeWords = [
        'error', 'problem', 'issue', 'bug', 'wrong', 'fail', 'failed',
        'broken', 'stuck', 'confused', 'frustrated', 'difficult', 'hard',
      ];
      
      // Question indicators
      final questionWords = [
        'how', 'what', 'why', 'when', 'where', 'which', 'can', 'should',
        '?', 'help', 'explain', 'understand',
      ];
      
      int positiveScore = 0;
      int negativeScore = 0;
      int questionScore = 0;
      
      for (final word in positiveWords) {
        if (text.contains(word)) positiveScore++;
      }
      
      for (final word in negativeWords) {
        if (text.contains(word)) negativeScore++;
      }
      
      for (final word in questionWords) {
        if (text.contains(word)) questionScore++;
      }
      
      // Determine tone based on scores
      if (questionScore >= 2) return 'questioning';
      if (positiveScore > negativeScore) return 'positive';
      if (negativeScore > positiveScore) return 'frustrated';
      return 'neutral';
      
    } catch (e) {
      print('❌ Tone Analysis Error: $e');
      return 'neutral';
    }
  }
  
  /// Process voice comment: transcribe, extract keywords, analyze tone
  static Future<Map<String, dynamic>> processVoiceComment({
    required String audioFilePath,
    required int duration,
  }) async {
    try {
      // Step 1: Transcribe audio
      final transcription = await transcribeAudio(audioFilePath);
      
      // Step 2: Extract keywords
      final keywords = await extractKeywords(transcription);
      
      // Step 3: Analyze tone
      final tone = await analyzeTone(transcription);
      
      return {
        'transcription': transcription,
        'keywords': keywords,
        'tone': tone,
        'duration': duration,
      };
      
    } catch (e) {
      print('❌ Voice Processing Error: $e');
      rethrow;
    }
  }
  
  /// Transcribe with AssemblyAI (FREE - No credit card needed!)
  static Future<String> _transcribeWithAssemblyAI(String audioFilePath) async {
    try {
      final file = File(audioFilePath);
      final bytes = await file.readAsBytes();
      
      // Step 1: Upload audio file
      print('📤 Uploading audio to AssemblyAI...');
      final uploadResponse = await http.post(
        Uri.parse('https://api.assemblyai.com/v2/upload'),
        headers: {
          'authorization': _speechApiKey,
          'content-type': 'application/octet-stream',
        },
        body: bytes,
      );
      
      if (uploadResponse.statusCode != 200) {
        throw Exception('Upload failed: ${uploadResponse.body}');
      }
      
      final uploadData = jsonDecode(uploadResponse.body);
      final audioUrl = uploadData['upload_url'];
      print('✅ Audio uploaded: $audioUrl');
      
      // Step 2: Request transcription
      print('🎙️ Requesting transcription...');
      final transcribeResponse = await http.post(
        Uri.parse('https://api.assemblyai.com/v2/transcript'),
        headers: {
          'authorization': _speechApiKey,
          'content-type': 'application/json',
        },
        body: jsonEncode({
          'audio_url': audioUrl,
          'language_code': 'en',
        }),
      );
      
      if (transcribeResponse.statusCode != 200) {
        throw Exception('Transcription request failed: ${transcribeResponse.body}');
      }
      
      final transcriptData = jsonDecode(transcribeResponse.body);
      final transcriptId = transcriptData['id'];
      print('⏳ Transcription ID: $transcriptId');
      
      // Step 3: Poll for result
      String status = 'processing';
      String? text;
      
      for (int i = 0; i < 60; i++) { // Max 60 attempts (30 seconds)
        await Future.delayed(const Duration(milliseconds: 500));
        
        final resultResponse = await http.get(
          Uri.parse('https://api.assemblyai.com/v2/transcript/$transcriptId'),
          headers: {'authorization': _speechApiKey},
        );
        
        if (resultResponse.statusCode == 200) {
          final resultData = jsonDecode(resultResponse.body);
          status = resultData['status'];
          
          if (status == 'completed') {
            text = resultData['text'];
            print('✅ Transcription complete: $text');
            break;
          } else if (status == 'error') {
            throw Exception('Transcription error: ${resultData['error']}');
          }
        }
      }
      
      return text ?? '[Transcription timeout - try again]';
      
    } catch (e) {
      print('❌ AssemblyAI Error: $e');
      return '[Transcription failed - check API key or internet connection]';
    }
  }
  
  /// Mock transcription for demo (remove when using real API)
  static String _getMockTranscription(String audioPath) {
    // Simulate different transcriptions based on audio path hash
    final hash = audioPath.hashCode % 10;
    
    final mockTranscriptions = [
      "Hey everyone, I'm having trouble with Flutter state management. Can someone explain the difference between setState and Provider?",
      "Great explanation! That really helped me understand how React hooks work. Thanks for sharing!",
      "I'm getting a null pointer exception in my Java code. I think it's related to the database connection. Any ideas?",
      "Just wanted to share a solution I found for the sorting algorithm problem. Using merge sort worked perfectly!",
      "Can anyone help me with Python list comprehensions? I'm not sure how to filter and transform data at the same time.",
      "This is exactly what I needed! The async await pattern makes so much more sense now. Appreciate the help!",
      "I'm stuck on this CSS flexbox layout. The items aren't aligning the way I expected. What am I doing wrong?",
      "Thanks for the code review! I refactored the component and it's much cleaner now. Performance improved too!",
      "Quick question about Git branches. Should I merge or rebase when integrating feature branches? What's the best practice?",
      "Solved it! The error was caused by a missing await keyword. Sometimes it's the small things that trip you up!",
    ];
    
    return mockTranscriptions[hash];
  }
  
  /// Generate waveform data (simplified)
  static List<double> generateWaveformData(int duration) {
    // Generate pseudo-random waveform for visualization
    final points = (duration * 10).clamp(20, 100); // 10 points per second, max 100
    return List.generate(points, (i) {
      final t = i / points;
      return 0.3 + 0.7 * (0.5 + 0.5 * sin(t * 6.28)) * ((i % 7) / 7);
    });
  }
}
