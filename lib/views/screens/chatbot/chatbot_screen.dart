// lib/views/screens/chatbot/chatbot_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/constant/app_theme.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Welcome message
    _messages.add(ChatMessage(
      text: "👋 Hi! I'm your AI learning assistant. Ask me anything about courses, events, or learning tips!",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });

    _textController.clear();
    _scrollToBottom();

    try {
      // Using Hugging Face's free API (Mistral-7B model)
      final response = await http.post(
        Uri.parse('https://api-inference.huggingface.co/models/mistralai/Mistral-7B-Instruct-v0.1'),
        headers: {
          'Authorization': '',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'inputs': 'You are a helpful e-learning assistant. Answer this question concisely: $text',
          'parameters': {
            'max_new_tokens': 200,
            'temperature': 0.7,
            'top_p': 0.95,
            'return_full_text': false,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String botReply = '';

        if (data is List && data.isNotEmpty) {
          botReply = data[0]['generated_text'] ?? 'I could not generate a response.';
        } else if (data is Map && data.containsKey('generated_text')) {
          botReply = data['generated_text'];
        } else {
          botReply = 'I received an unexpected response format.';
        }

        setState(() {
          _messages.add(ChatMessage(
            text: botReply.trim(),
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isTyping = false;
        });
      } else {
        // Fallback responses if API fails
        setState(() {
          _messages.add(ChatMessage(
            text: _getFallbackResponse(text),
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isTyping = false;
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: _getFallbackResponse(text),
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isTyping = false;
      });
    }

    _scrollToBottom();
  }

  String _getFallbackResponse(String userMessage) {
    final lower = userMessage.toLowerCase();

    if (lower.contains('course') || lower.contains('learn')) {
      return "📚 We offer various courses in Flutter, Data Science, UI/UX Design, and more! Check the Courses section to explore our offerings.";
    } else if (lower.contains('event')) {
      return "🎉 Browse upcoming events in the Events tab. You can register for workshops, webinars, and networking sessions!";
    } else if (lower.contains('schedule')) {
      return "📅 Check your personalized schedule in the Schedule section. It shows all your registered events and courses.";
    } else if (lower.contains('game') || lower.contains('casino')) {
      return "🎰 Try our casino games! Play Slot Machine, Blackjack, and Roulette to earn coins and have fun!";
    } else if (lower.contains('help')) {
      return "💡 I can help you with:\n• Finding courses\n• Event information\n• Learning tips\n• Platform navigation\n\nWhat would you like to know?";
    } else {
      return "🤔 I'm here to help with your e-learning journey! Ask me about courses, events, schedules, or anything related to learning.";
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Text('🤖', style: TextStyle(fontSize: 20)),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Assistant', style: TextStyle(fontSize: 18)),
                Text(
                  'Always here to help',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add(ChatMessage(
                  text: "👋 Chat cleared! How can I help you today?",
                  isUser: false,
                  timestamp: DateTime.now(),
                ));
              });
            },
            tooltip: 'Clear chat',
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick suggestions
          Container(
            height: 50,
            color: AppTheme.primaryColor.withOpacity(0.1),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _buildQuickChip('📚 Courses', 'Tell me about available courses'),
                _buildQuickChip('🎉 Events', 'What events are upcoming?'),
                _buildQuickChip('💡 Tips', 'Give me learning tips'),
                _buildQuickChip('🎰 Games', 'Tell me about the casino games'),
              ],
            ),
          ),

          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _buildTypingIndicator();
                }
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          // Input area
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: 'Ask me anything...',
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          prefixIcon: const Icon(Icons.chat_bubble_outline),
                        ),
                        onSubmitted: _sendMessage,
                        textInputAction: TextInputAction.send,
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: AppTheme.primaryColor,
                      radius: 24,
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: () => _sendMessage(_textController.text),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String label, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: ActionChip(
        label: Text(label),
        onPressed: () => _sendMessage(message),
        backgroundColor: Colors.white,
        side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isUser
              ? AppTheme.primaryColor
              : Colors.grey[300],
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: message.isUser ? const Radius.circular(4) : null,
            bottomLeft: !message.isUser ? const Radius.circular(4) : null,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: message.isUser ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                color: message.isUser
                    ? Colors.white.withOpacity(0.7)
                    : Colors.black54,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0),
            const SizedBox(width: 4),
            _buildDot(1),
            const SizedBox(width: 4),
            _buildDot(2),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, double value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[600]?.withOpacity(
              (value + index * 0.3) % 1.0,
            ),
            shape: BoxShape.circle,
          ),
        );
      },
      onEnd: () {
        if (mounted) setState(() {});
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}