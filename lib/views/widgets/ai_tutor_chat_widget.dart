import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/ai_tutor_service.dart';
import '../../database/database_helper.dart';
import '../../providers/auth_provider.dart';

/// Message model for chat
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String>? topics;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.topics,
  });
}

/// AI Tutor Chat Widget - Interactive chat interface with AI tutor
class AITutorChatWidget extends StatefulWidget {
  final Map<String, String>? postContext;
  final int? postId;
  final String initialQuestion;

  const AITutorChatWidget({
    Key? key,
    this.postContext,
    this.postId,
    this.initialQuestion = '',
  }) : super(key: key);

  @override
  State<AITutorChatWidget> createState() => _AITutorChatWidgetState();
}

class _AITutorChatWidgetState extends State<AITutorChatWidget>
    with SingleTickerProviderStateMixin {
  final AITutorService _tutorService = AITutorService();
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  
  bool _isLoading = false;
  String _selectedLanguage = 'en';
  late AnimationController _animationController;

  final List<Map<String, String>> _languageOptions = [
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
    {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
    {'code': 'ar', 'name': 'العربية', 'flag': '🇸🇦'},
    {'code': 'es', 'name': 'Español', 'flag': '🇪🇸'},
    {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪'},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Add welcome message
    _addMessage(
      ChatMessage(
        text: _getWelcomeMessage(),
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );

    // If there's an initial question, ask it
    if (widget.initialQuestion.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _questionController.text = widget.initialQuestion;
        _askQuestion();
      });
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String _getWelcomeMessage() {
    final context = widget.postContext;
    if (context != null && context['title'] != null) {
      return '''👋 Hello! I'm your AI Tutor Assistant!

I see you're viewing: "${context['title']}"

I'm here to help you understand this topic better. Feel free to ask any questions! 😊

**Quick tips:**
- Ask specific questions for better answers
- I can explain concepts step-by-step
- Request examples or code snippets
- Ask for clarification anytime

What would you like to know?''';
    }
    return '''👋 Hello! I'm your AI Tutor Assistant!

I'm here to help you learn and understand programming concepts.

**I can help with:**
- 💡 Explaining concepts clearly
- 🔍 Debugging problems
- 📚 Providing examples
- ✨ Best practices and tips

What would you like to learn today?''';
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _askQuestion() async {
    final question = _questionController.text.trim();
    if (question.isEmpty || _isLoading) return;

    // Add user message
    _addMessage(
      ChatMessage(
        text: question,
        isUser: true,
        timestamp: DateTime.now(),
      ),
    );

    _questionController.clear();
    setState(() => _isLoading = true);

    try {
      // Prepare conversation history
      final conversationHistory = _messages
          .where((m) => m.text != _getWelcomeMessage())
          .map((m) => {
                'role': m.isUser ? 'user' : 'assistant',
                'content': m.text,
              })
          .toList();

      // Ask the AI tutor
      final response = await _tutorService.askQuestion(
        question: question,
        postContext: widget.postContext,
        language: _selectedLanguage,
        conversationHistory: conversationHistory,
      );

      if (response['success'] == true) {
        final answer = response['response'] as String;
        final topics = response['topics'] as List<String>?;
        
        // Add AI response
        _addMessage(
          ChatMessage(
            text: answer,
            isUser: false,
            timestamp: DateTime.now(),
            topics: topics,
          ),
        );
        
        // Save conversation to database
        if (mounted) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          final userId = authProvider.user?.id;
          
          if (userId != null) {
            await DatabaseHelper.instance.saveAITutorConversation(
              userId: userId,
              postId: widget.postId,
              question: question,
              answer: answer,
              topics: topics,
              language: _selectedLanguage,
            );
          }
        }
      } else {
        // Show error message
        _addMessage(
          ChatMessage(
            text: '⚠️ ${response['message'] ?? 'Sorry, I encountered an error. Please try again.'}',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      print('❌ Error asking question: $e');
      _addMessage(
        ChatMessage(
          text: '❌ Oops! Something went wrong. Please try asking again.',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade50,
            Colors.purple.shade50,
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text('🤖', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Tutor Assistant',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Powered by Gemini AI',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade600, Colors.blue.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          elevation: 0,
          actions: [
            // Language selector
            PopupMenuButton<String>(
              icon: const Icon(Icons.language, color: Colors.white),
              tooltip: 'Select Language',
              onSelected: (languageCode) {
                setState(() => _selectedLanguage = languageCode);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Language changed to ${_languageOptions.firstWhere((l) => l['code'] == languageCode)['name']}',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              itemBuilder: (context) => _languageOptions.map((lang) {
                return PopupMenuItem<String>(
                  value: lang['code'],
                  child: Row(
                    children: [
                      Text(lang['flag']!, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Text(lang['name']!),
                      if (_selectedLanguage == lang['code']) ...[
                        const Spacer(),
                        const Icon(Icons.check, color: Colors.green, size: 20),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
            IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.white),
              tooltip: 'About AI Tutor',
              onPressed: _showAboutDialog,
            ),
          ],
        ),
        body: Column(
          children: [
            // Chat messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _buildMessageBubble(message);
                },
              ),
            ),

            // Loading indicator
            if (_isLoading)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Row(
                          children: List.generate(3, (index) {
                            final delay = index * 0.3;
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(
                                  0.3 +
                                      0.7 *
                                          ((_animationController.value +
                                                      delay) %
                                                  1.0),
                                ),
                                shape: BoxShape.circle,
                              ),
                            );
                          }),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'AI is thinking...',
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

            // Input area
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _questionController,
                        decoration: InputDecoration(
                          hintText: 'Ask me anything...',
                          hintStyle: GoogleFonts.poppins(
                            color: Colors.grey.shade400,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _askQuestion(),
                        enabled: !_isLoading,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.purple.shade600, Colors.blue.shade600],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _isLoading ? null : _askQuestion,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Text('🤖', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: message.isUser
                        ? LinearGradient(
                            colors: [
                              Colors.purple.shade600,
                              Colors.blue.shade600,
                            ],
                          )
                        : null,
                    color: message.isUser ? null : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SelectableText(
                    message.text,
                    style: GoogleFonts.poppins(
                      color: message.isUser ? Colors.white : Colors.black87,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    _formatTime(message.timestamp),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
                // Show topics if available
                if (message.topics != null && message.topics!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: message.topics!.map((topic) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '#$topic',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.purple.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade600, Colors.blue.shade600],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Text('🤖'),
            const SizedBox(width: 8),
            Text(
              'About AI Tutor',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your AI-powered learning assistant',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoRow(Icons.auto_awesome, 'Powered by',
                  'Google Gemini AI (1.5 Flash)'),
              _buildInfoRow(
                  Icons.language, 'Languages', '5+ languages supported'),
              _buildInfoRow(
                  Icons.speed, 'Response Time', 'Usually 2-5 seconds'),
              _buildInfoRow(Icons.security, 'Privacy',
                  'Conversations are not stored permanently'),
              const SizedBox(height: 16),
              Text(
                '💡 Tips for Best Results:',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              _buildTipRow('Ask specific questions'),
              _buildTipRow('Include code examples when debugging'),
              _buildTipRow('Request step-by-step explanations'),
              _buildTipRow('Follow up for clarification'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Free tier: 60 requests/minute',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it!',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.purple.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipRow(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: GoogleFonts.poppins(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
