import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/constant/app_theme.dart';
import '../../../models/postulation_model.dart';
import '../../../models/comment_model.dart';
import '../../../models/debate_model.dart';
import '../../../models/comment_quality_model.dart';
import '../../../providers/comment_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/notifications_provider.dart';
import '../../../database/database_helper.dart';
import '../../../services/ai_debate_service.dart';
import '../../../services/ai_comment_rating_service.dart';
import '../../../services/ai_mentor_service.dart';
import '../../../services/voice_processing_service.dart';
import '../../../services/content_scraper_service.dart';
import '../../../models/voice_comment_model.dart';
import '../../widgets/mention_text_field.dart';
import '../../widgets/debate_view.dart';
import '../../widgets/voice_recorder_widget.dart';
import '../../widgets/voice_player_widget.dart';
import '../../widgets/voice_playlist_player.dart';
import '../../widgets/ai_tutor_chat_widget.dart';
import '../discover/discover_screen.dart';
import 'create_post_screen.dart';

class PostDetailsScreen extends StatefulWidget {
  final Post post;
  const PostDetailsScreen({super.key, required this.post});

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final Map<int, TextEditingController> _replyControllers = {};
  final Map<int, bool> _showReplyInput = {};
  final Map<int, bool> _showReplies = {}; // Track which comments have visible replies
  Map<int, String> _userNames = {}; // Cache for user names
  Map<String, int> _reactionCounts = {};
  String? _userReactionType;
  Post? _currentPost; // Store current post data
  String _commentSortType = 'pertinence'; // 'pertinence' or 'recent'
  
  // Mention tracking
  final GlobalKey<MentionTextFieldState> _mainCommentMentionKey = GlobalKey();
  final Map<int, GlobalKey<MentionTextFieldState>> _replyMentionKeys = {};
  List<int> _mainCommentMentions = [];
  final Map<int, List<int>> _replyMentions = {}; // commentId -> mentioned user IDs
  
  // Debate mode tracking
  bool _debateModeEnabled = false;
  DebateAnalysis? _debateAnalysis;
  bool _loadingDebate = false;
  
  // Comment quality ratings cache
  Map<int, CommentQuality> _commentRatings = {};
  bool _ratingsLoaded = false;
  
  // AI Mentor tracking
  bool _loadingMentorHint = false;
  bool _mentorHintGenerated = false;
  
  // Voice comments tracking
  Map<int, VoiceComment> _voiceComments = {}; // commentId -> VoiceComment
  bool _isProcessingVoice = false;
  List<VoicePlaylistItem> _voicePlaylist = [];

  @override
  void initState() {
    super.initState();
    _currentPost = widget.post; // Initialize with the passed post
    _loadComments();
    _loadPostAuthor();
    _loadReactions();
    _loadVoiceComments();
  }
  

  
  Future<void> _loadReactions() async {
    final counts = await DatabaseHelper.instance.getReactionCounts('post', widget.post.id!);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?.id ?? 0;
    
    final userReaction = await DatabaseHelper.instance.getUserReaction(
      'post',
      widget.post.id!,
      currentUserId,
    );
    
    if (mounted) {
      setState(() {
        _reactionCounts = counts;
        _userReactionType = userReaction?['reactionType'] as String?;
      });
    }
  }
  
  Future<void> _addReaction(String reactionType) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?.id ?? 0;
    
    if (currentUserId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to react')),
      );
      return;
    }
    
    await DatabaseHelper.instance.toggleReaction(
      'post',
      widget.post.id!,
      currentUserId,
      reactionType,
    );
    
    await _loadReactions();
    Navigator.pop(context); // Close the reaction picker
  }
  
  void _showReactionPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: FadeInUp(
          duration: const Duration(milliseconds: 400),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  Colors.grey[50]!,
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(35),
                topRight: Radius.circular(35),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, -10),
                  spreadRadius: 5,
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle with glow effect
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.3),
                        AppTheme.primaryColor.withOpacity(0.6),
                        AppTheme.primaryColor.withOpacity(0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                
                // Title with enhanced styling
                FadeInDown(
                  duration: const Duration(milliseconds: 500),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.15),
                          AppTheme.primaryColor.withOpacity(0.08),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.2),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.emoji_emotions,
                            color: AppTheme.primaryColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Choose your reaction',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                
                // Reactions grid with staggered animation
                Pulse(
                  duration: const Duration(milliseconds: 600),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildReactionButton('like', '👍', delay: 0),
                            _buildReactionButtonWithColor('love', '❤️', Colors.red, delay: 50),
                            _buildReactionButton('dislike', '👎', delay: 100),
                            _buildReactionButton('care', '🤗', delay: 150),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildReactionButton('haha', '😂', delay: 200),
                            _buildReactionButton('wow', '😮', delay: 250),
                            _buildReactionButton('sad', '😢', delay: 300),
                            _buildReactionButton('angry', '😠', delay: 350),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _showReactionsList() async {
    // Fetch all reactions for this post
    final reactions = await DatabaseHelper.instance.getReactionsByTarget('post', widget.post.id!);
    
    // Group reactions by type
    Map<String, List<Map<String, dynamic>>> groupedReactions = {};
    for (var reaction in reactions) {
      String type = reaction['reactionType'] as String;
      if (!groupedReactions.containsKey(type)) {
        groupedReactions[type] = [];
      }
      groupedReactions[type]!.add(reaction);
    }
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: FadeInUp(
          duration: const Duration(milliseconds: 400),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  Colors.grey[50]!,
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(35),
                topRight: Radius.circular(35),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, -10),
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.3),
                        AppTheme.primaryColor.withOpacity(0.6),
                        AppTheme.primaryColor.withOpacity(0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Icon(
                        Icons.people_alt_rounded,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Reactions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Spacer(),
                      Text(
                        '${reactions.length}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Reactions list
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: groupedReactions.entries.map((entry) {
                      String reactionType = entry.key;
                      List<Map<String, dynamic>> users = entry.value;
                      
                      return FadeInLeft(
                        duration: const Duration(milliseconds: 400),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey[200]!,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Reaction type header
                              Row(
                                children: [
                                  if (reactionType == 'love')
                                    Icon(
                                      Icons.favorite,
                                      size: 24,
                                      color: Colors.red,
                                    )
                                  else
                                    Text(
                                      _getReactionEmoji(reactionType),
                                      style: TextStyle(fontSize: 24),
                                    ),
                                  const SizedBox(width: 8),
                                  Text(
                                    reactionType.capitalize(),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${users.length}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Divider(height: 1, color: Colors.grey[300]),
                              const SizedBox(height: 12),
                              
                              // Users list
                              ...users.map((reaction) {
                                return FutureBuilder<String>(
                                  future: _getUserName(reaction['userId'] as int),
                                  builder: (context, snapshot) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                            child: Icon(
                                              Icons.person,
                                              color: AppTheme.primaryColor,
                                              size: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              snapshot.data ?? 'Loading...',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.grey[800],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildReactionButton(String reactionType, String emoji, {int delay = 0}) {
    final isSelected = _userReactionType == reactionType;
    final count = _reactionCounts[reactionType] ?? 0;
    
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      delay: Duration(milliseconds: delay),
      child: InkWell(
        onTap: () => _addReaction(reactionType),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 72,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: isSelected 
                ? LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.25),
                      AppTheme.primaryColor.withOpacity(0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [
                      Colors.grey[50]!,
                      Colors.grey[100]!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(20),
            border: isSelected
                ? Border.all(
                    color: AppTheme.primaryColor,
                    width: 2.5,
                  )
                : Border.all(
                    color: Colors.grey[300]!,
                    width: 1.5,
                  ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                      spreadRadius: 2,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.scale(
                scale: isSelected ? 1.15 : 1.0,
                child: Text(
                  emoji,
                  style: TextStyle(
                    fontSize: 34,
                    shadows: isSelected
                        ? [
                            Shadow(
                              color: Colors.black.withOpacity(0.1),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
              if (count > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.primaryColor.withOpacity(0.8),
                            ],
                          )
                        : null,
                    color: isSelected ? null : Colors.grey[400],
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildReactionButtonWithColor(String reactionType, String emoji, Color emojiColor, {int delay = 0}) {
    final isSelected = _userReactionType == reactionType;
    final count = _reactionCounts[reactionType] ?? 0;
    
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      delay: Duration(milliseconds: delay),
      child: InkWell(
        onTap: () => _addReaction(reactionType),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 72,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: isSelected 
                ? LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.25),
                      AppTheme.primaryColor.withOpacity(0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [
                      Colors.grey[50]!,
                      Colors.grey[100]!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(20),
            border: isSelected
                ? Border.all(
                    color: AppTheme.primaryColor,
                    width: 2.5,
                  )
                : Border.all(
                    color: Colors.grey[300]!,
                    width: 1.5,
                  ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                      spreadRadius: 2,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.scale(
                scale: isSelected ? 1.15 : 1.0,
                child: Icon(
                  Icons.favorite,
                  size: 34,
                  color: emojiColor,
                  shadows: isSelected
                      ? [
                          Shadow(
                            color: emojiColor.withOpacity(0.5),
                            offset: const Offset(0, 3),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.primaryColor.withOpacity(0.8),
                            ],
                          )
                        : null,
                    color: isSelected ? null : Colors.grey[400],
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _commentController.dispose();
    for (var controller in _replyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _loadComments() {
    final commentsProvider = Provider.of<CommentsProvider>(context, listen: false);
    commentsProvider.loadComments(widget.post.id!);
    // Load/evaluate comment ratings after comments are loaded
    _evaluateCommentRatings();
    // Check if AI Mentor help is needed
    _checkForMentorHelp();
  }
  
  /// Check if post needs AI Mentor help and generate hint automatically
  void _checkForMentorHelp() async {
    // Wait for comments to load
    await Future.delayed(const Duration(milliseconds: 800));
    
    if (!mounted) return;
    
    final commentsProvider = Provider.of<CommentsProvider>(context, listen: false);
    final comments = commentsProvider.comments;
    
    // Check if mentor help is needed (no comments + post is old enough)
    if (AIMentorService.needsMentorHelp(
      commentCount: comments.length,
      postDate: widget.post.date,
    )) {
      // Auto-generate hint silently
      await _generateAIMentorHint();
    }
  }
  
  /// Evaluate quality ratings for all comments
  Future<void> _evaluateCommentRatings() async {
    final commentsProvider = Provider.of<CommentsProvider>(context, listen: false);
    
    // Wait a bit for comments to load
    await Future.delayed(const Duration(milliseconds: 500));
    
    final comments = commentsProvider.comments;
    if (comments.isEmpty) return;
    
    for (final comment in comments) {
      if (comment.id == null) continue;
      
      // Check if rating already exists in comment
      if (comment.qualityRating != null) {
        // Use cached rating
        if (mounted) {
          setState(() {
            _commentRatings[comment.id!] = CommentQuality.fromCriteria(
              commentId: comment.id!,
              relevance: comment.qualityRating! * 0.4 / 0.4, // Reverse weighted average
              clarity: comment.qualityRating! * 0.2 / 0.2,
              constructiveness: comment.qualityRating! * 0.2 / 0.2,
              tone: comment.qualityRating! * 0.2 / 0.2,
            );
          });
        }
      } else {
        // Evaluate new rating
        try {
          final quality = await AICommentRatingService.evaluateComment(
            comment: comment,
            postContent: widget.post.description,
            postTitle: widget.post.title,
          );
          
          // Save rating to database
          await DatabaseHelper.instance.updateCommentQuality(
            comment.id!,
            quality.overallScore,
          );
          
          // Update comment object
          comment.qualityRating = quality.overallScore;
          
          if (mounted) {
            setState(() {
              _commentRatings[comment.id!] = quality;
            });
          }
        } catch (e) {
          print('❌ Failed to evaluate comment ${comment.id}: $e');
        }
      }
    }
    
    if (mounted) {
      setState(() {
        _ratingsLoaded = true;
      });
    }
  }
  
  Future<void> _loadPostAuthor() async {
    final user = await DatabaseHelper.instance.getUserById(widget.post.userId);
    if (user != null && mounted) {
      setState(() {
        _userNames[widget.post.userId] = '${user['prenom']} ${user['nom']}';
      });
    }
  }
  
  Future<void> _analyzeDebate() async {
    final commentsProvider = Provider.of<CommentsProvider>(context, listen: false);
    
    // Need at least 3 comments for debate mode
    if (commentsProvider.comments.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Need at least 3 comments to analyze the debate'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    setState(() {
      _loadingDebate = true;
    });
    
    try {
      final analysis = await AIDebateService.analyzeDebate(
        postId: widget.post.id.toString(),
        postContent: widget.post.description,
        comments: commentsProvider.comments,
        userNames: _userNames,
      );
      
      if (mounted) {
        setState(() {
          _debateAnalysis = analysis;
          _debateModeEnabled = true;
          _loadingDebate = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingDebate = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to analyze debate: $e')),
        );
      }
    }
  }
  
  void _toggleDebateMode() {
    if (_debateModeEnabled) {
      // Turn off debate mode
      setState(() {
        _debateModeEnabled = false;
      });
    } else {
      // Analyze and enable debate mode
      _analyzeDebate();
    }
  }
  
  /// Open AI Tutor chat assistant
  void _openAITutor() {
    final post = _currentPost ?? widget.post;
    
    // Prepare post context for the AI tutor
    final Map<String, String> postContext = {
      'title': post.title,
      'content': post.description,
      'tags': post.tags,
    };
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AITutorChatWidget(
          postContext: postContext,
          postId: post.id,
        ),
      ),
    );
  }

  /// Build the Discover Related Articles suggestion card
  Widget _buildDiscoverSuggestionCard() {
    final post = _currentPost ?? widget.post;
    
    // Extract topics from the post
    final topics = ContentScraperService.extractTopicsFromPost(
      title: post.title,
      description: post.description,
      tags: post.tags,
    );

    // If no topics detected, don't show the card
    if (topics.isEmpty) {
      return const SizedBox.shrink();
    }

    final suggestionMessage = ContentScraperService.getSuggestionMessage(topics);

    return FadeInUp(
      duration: const Duration(milliseconds: 700),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.shade50,
              Colors.blue.shade50,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.purple.shade200,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              // Navigate to Discover screen with related topics
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DiscoverScreen(relatedTopics: topics),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with icon
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.purple.shade600,
                              Colors.blue.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Discover Related Articles',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Powered by AI',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.purple.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.purple.shade600,
                        size: 18,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Suggestion message
                  Text(
                    suggestionMessage,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Topic chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: topics.take(5).map((topic) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.purple.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.label,
                              size: 14,
                              color: Colors.purple.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              topic.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // CTA Button
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple.shade600,
                          Colors.blue.shade600,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.article,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Browse Related Articles',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  /// Generate AI Mentor hint for this post
  Future<void> _generateAIMentorHint({bool regenerate = false}) async {
    setState(() {
      _loadingMentorHint = true;
    });
    
    try {
      final hint = await AIMentorService.generateHint(
        postTitle: widget.post.title,
        postContent: widget.post.description,
        category: widget.post.tags,
        regenerate: regenerate,
      );
      
      // Create AI Mentor comment
      final mentorComment = Comment(
        postId: widget.post.id!,
        userId: AIMentorService.aiMentorUserId,
        content: hint,
        date: DateTime.now().toIso8601String(),
        parentCommentId: null,
      );
      
      final commentsProvider = Provider.of<CommentsProvider>(context, listen: false);
      await commentsProvider.addComment(mentorComment);
      
      if (mounted) {
        setState(() {
          _loadingMentorHint = false;
          _mentorHintGenerated = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.white),
                SizedBox(width: 8),
                Text('AI Mentor hint added!'),
              ],
            ),
            backgroundColor: Color(0xFFFF9800),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingMentorHint = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate hint: $e')),
        );
      }
    }
  }
  
  Future<String> _getUserName(int userId) async {
    // Handle AI Mentor special case
    if (userId == AIMentorService.aiMentorUserId) {
      return AIMentorService.aiMentorName;
    }
    
    if (_userNames.containsKey(userId)) {
      return _userNames[userId]!;
    }
    
    final user = await DatabaseHelper.instance.getUserById(userId);
    if (user != null) {
      final name = '${user['prenom']} ${user['nom']}';
      if (mounted) {
        setState(() {
          _userNames[userId] = name;
        });
      }
      return name;
    }
    return 'Unknown User';
  }
  
  /// Load voice comments for this post
  Future<void> _loadVoiceComments() async {
    // TODO: Load from database when voice_comments table is created
    // For now, using mock data structure
    setState(() {
      _voiceComments = {};
      _voicePlaylist = [];
    });
  }
  
  /// Show voice recorder dialog
  void _showVoiceRecorder() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: VoiceRecorderWidget(
          onRecordingComplete: (audioPath, duration) async {
            Navigator.pop(context);
            await _processVoiceComment(audioPath, duration, null);
          },
          onCancel: () => Navigator.pop(context),
        ),
      ),
    );
  }
  
  /// Process voice comment: transcribe, extract keywords, analyze tone
  Future<void> _processVoiceComment(
    String audioPath,
    int duration,
    int? parentCommentId,
  ) async {
    setState(() => _isProcessingVoice = true);
    
    try {
      // Show processing message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('Processing voice comment...'),
              ],
            ),
            duration: Duration(seconds: 3),
            backgroundColor: Color(0xFF673AB7),
          ),
        );
      }
      
      // Process voice: transcribe + extract keywords + analyze tone
      print('🎤 Processing voice from: $audioPath, Duration: ${duration}s');
      final processed = await VoiceProcessingService.processVoiceComment(
        audioFilePath: audioPath,
        duration: duration,
      );
      
      print('🎤 Processing complete:');
      print('   - Transcription: ${processed['transcription']}');
      print('   - Keywords: ${processed['keywords']}');
      print('   - Tone: ${processed['tone']}');
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.user?.id ?? 0;
      
      // Get transcription or use fallback
      String transcriptionText = processed['transcription'] as String? ?? '';
      if (transcriptionText.trim().isEmpty) {
        transcriptionText = '🎤 [Voice message - Recording was too quiet or no speech detected. Try speaking louder and closer to the microphone]';
        print('⚠️ Empty transcription, using fallback message');
      }
      
      // Create comment with transcription
      final comment = Comment(
        postId: widget.post.id!,
        parentCommentId: parentCommentId,
        userId: currentUserId,
        content: transcriptionText,
        date: DateTime.now().toIso8601String(),
        hasVoice: true,
      );
      
      // Add comment to database
      final commentsProvider = Provider.of<CommentsProvider>(context, listen: false);
      print('🎤 Adding voice comment with content: "${comment.content}"');
      final commentId = await commentsProvider.addComment(comment);
      print('🎤 Comment added with ID: $commentId');
      
      // Check if comment was added successfully
      if (commentId <= 0) {
        throw Exception('Failed to add comment to database');
      }
      
      // Create voice comment record
      final voiceComment = VoiceComment(
        commentId: commentId,
        audioUrl: audioPath,
        transcription: processed['transcription'] as String,
        duration: duration,
        extractedTags: (processed['keywords'] as List<dynamic>).cast<String>(),
        tone: processed['tone'] as String?,
        recordedAt: DateTime.now(),
      );
      
      // TODO: Save to database when voice_comments table is created
      // For now, store in memory
      setState(() {
        _voiceComments[commentId] = voiceComment;
        _updateVoicePlaylist();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '🎤 Voice comment added! ${voiceComment.extractedTags.take(3).join(" ")}',
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF4CAF50),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing voice: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isProcessingVoice = false);
    }
  }
  
  /// Update voice playlist for "Play All" feature
  void _updateVoicePlaylist() async {
    final commentsProvider = Provider.of<CommentsProvider>(context, listen: false);
    final comments = commentsProvider.comments;
    
    final playlist = <VoicePlaylistItem>[];
    int position = 0;
    
    for (final comment in comments) {
      if (comment.hasVoice && _voiceComments.containsKey(comment.id)) {
        final userName = await _getUserName(comment.userId);
        playlist.add(VoicePlaylistItem(
          voiceComment: _voiceComments[comment.id]!,
          authorName: userName,
          commentContent: comment.content,
          isReply: comment.parentCommentId != null,
          position: position++,
        ));
      }
    }
    
    setState(() {
      _voicePlaylist = playlist;
    });
  }
  
  /// Show podcast mode (Play All)
  void _showPodcastMode() {
    if (_voicePlaylist.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No voice comments to play'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          body: VoicePlaylistPlayer(
            playlist: _voicePlaylist,
            onClose: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }

  void _addComment(String text, {int? parentCommentId}) async {
    if (text.trim().isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null) return;

    // Get mentioned user IDs
    List<int> mentionedIds = [];
    if (parentCommentId != null) {
      mentionedIds = _replyMentionKeys[parentCommentId]?.currentState?.getMentionedUserIds() ?? [];
    } else {
      mentionedIds = _mainCommentMentionKey.currentState?.getMentionedUserIds() ?? [];
    }

    final newComment = Comment(
      postId: widget.post.id!,
      userId: authProvider.user!.id!,
      content: text.trim(),
      date: DateTime.now().toIso8601String(),
      parentCommentId: parentCommentId,
      mentionedUserIds: mentionedIds.isEmpty ? null : mentionedIds.join(','),
    );

    final commentId = await Provider.of<CommentsProvider>(context, listen: false).addComment(newComment);
    if (commentId > 0) {
      final notificationsProvider = Provider.of<NotificationsProvider>(context, listen: false);
      final commenterName = authProvider.user!.fullName;
      final currentUserId = authProvider.user!.id!;
      
      // Notify mentioned users
      for (final mentionedUserId in mentionedIds) {
        if (mentionedUserId != currentUserId) {
          await notificationsProvider.createNotification(
            userId: mentionedUserId,
            fromUserId: currentUserId,
            type: 'mention',
            message: '$commenterName mentioned you in a comment',
            postId: widget.post.id!,
            commentId: newComment.id,
          );
        }
      }
      
      if (parentCommentId != null) {
        // This is a reply to a comment
        // 1. Notify the parent comment author (if replier is not the comment author)
        final commentsProvider = Provider.of<CommentsProvider>(context, listen: false);
        final parentComment = commentsProvider.comments.firstWhere(
          (c) => c.id == parentCommentId,
          orElse: () => Comment(postId: widget.post.id!, userId: 0, content: '', date: ''),
        );
        
        if (parentComment.userId != 0 && parentComment.userId != currentUserId && !mentionedIds.contains(parentComment.userId)) {
          await notificationsProvider.createNotification(
            userId: parentComment.userId,
            fromUserId: currentUserId,
            type: 'reply',
            message: '$commenterName replied to your comment',
            postId: widget.post.id!,
            commentId: newComment.id,
          );
        }
        
        // 2. Also notify the post author (if replier is not the post author and post author is not the comment author)
        if (widget.post.userId != currentUserId && widget.post.userId != parentComment.userId && !mentionedIds.contains(widget.post.userId)) {
          await notificationsProvider.createNotification(
            userId: widget.post.userId,
            fromUserId: currentUserId,
            type: 'reply',
            message: '$commenterName replied to a comment on your post',
            postId: widget.post.id!,
            commentId: newComment.id,
          );
        }
        
        // Clear reply input
        _replyControllers[parentCommentId]?.clear();
        _replyMentionKeys[parentCommentId]?.currentState?.clearMentions();
        setState(() {
          _showReplyInput[parentCommentId] = false;
        });
      } else {
        // This is a direct comment on the post
        // Notify the post author (if commenter is not the author and not already mentioned)
        if (widget.post.userId != currentUserId && !mentionedIds.contains(widget.post.userId)) {
          await notificationsProvider.createNotification(
            userId: widget.post.userId,
            fromUserId: currentUserId,
            type: 'comment',
            message: '$commenterName commented on your post',
            postId: widget.post.id!,
            commentId: newComment.id,
          );
        }
        
        // Clear main comment input
        _commentController.clear();
        _mainCommentMentionKey.currentState?.clearMentions();
      }
    }
  }

  void _showEditPostDialog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePostScreen(post: _currentPost),
      ),
    );
    
    // Update with returned post and reload from database for fresh data
    if (result != null && result is Post) {
      // First update with the returned post for immediate UI update
      setState(() {
        _currentPost = result;
      });
      
      // Then reload from database to ensure we have the latest saved data
      await _reloadPostData();
    }
  }

  void _showDeletePostDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.warning_rounded, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Delete Post',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
          style: TextStyle(fontSize: 15, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final result = await DatabaseHelper.instance.deletePost(widget.post.id!);
              if (result) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to previous screen
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 12),
                        Text('Post deleted successfully!'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.error, color: Colors.white),
                        const SizedBox(width: 12),
                        Text('Failed to delete post'),
                      ],
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditCommentDialog(Comment comment, CommentsProvider provider) {
    final TextEditingController editController = TextEditingController(text: comment.content);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => FadeInDown(
        duration: const Duration(milliseconds: 300),
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.edit_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit Comment',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Make your changes below',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Comment',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: TextField(
                          controller: editController,
                          maxLines: 5,
                          autofocus: true,
                          style: const TextStyle(fontSize: 15, height: 1.5),
                          decoration: InputDecoration(
                            hintText: 'Write your comment here...',
                            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.grey[200]!),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Cancel button
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          // Save button
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryColor,
                                  AppTheme.primaryColor.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () async {
                                  final newContent = editController.text.trim();
                                  if (newContent.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            Icon(Icons.error_outline, color: Colors.white),
                                            const SizedBox(width: 12),
                                            Text('Comment cannot be empty'),
                                          ],
                                        ),
                                        backgroundColor: Colors.red,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        margin: const EdgeInsets.all(16),
                                      ),
                                    );
                                    return;
                                  }

                                  final updatedComment = Comment(
                                    id: comment.id,
                                    postId: comment.postId,
                                    userId: comment.userId,
                                    content: newContent,
                                    date: comment.date,
                                    parentCommentId: comment.parentCommentId,
                                  );

                                  final success = await provider.updateComment(updatedComment);
                                  Navigator.pop(context);
                                  
                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            Icon(Icons.check_circle_outline, color: Colors.white),
                                            const SizedBox(width: 12),
                                            Text('Comment updated successfully!'),
                                          ],
                                        ),
                                        backgroundColor: Colors.green,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        margin: const EdgeInsets.all(16),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            Icon(Icons.error_outline, color: Colors.white),
                                            const SizedBox(width: 12),
                                            Text('Failed to update comment'),
                                          ],
                                        ),
                                        backgroundColor: Colors.red,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        margin: const EdgeInsets.all(16),
                                      ),
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                                  child: Row(
                                    children: [
                                      Icon(Icons.save_rounded, color: Colors.white, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Save',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
        ),
      ),
    );
  }

  void _showDeleteCommentDialog(Comment comment, CommentsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.warning_rounded, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Delete Comment',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this comment? This action cannot be undone.',
          style: TextStyle(fontSize: 15, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await provider.deleteComment(comment);
              Navigator.pop(context);
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 12),
                        Text('Comment deleted successfully!'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.error, color: Colors.white),
                        const SizedBox(width: 12),
                        Text('Failed to delete comment'),
                      ],
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _reloadPostData() async {
    try {
      final postsData = await DatabaseHelper.instance.getAllPosts();
      final posts = postsData.map((map) => Post.fromMap(map)).toList();
      final updatedPost = posts.firstWhere(
        (p) => p.id == widget.post.id,
        orElse: () => widget.post,
      );
      
      if (mounted) {
        setState(() {
          _currentPost = updatedPost;
        });
      }
    } catch (e) {
      print('Error reloading post: $e');
    }
  }
  
  String _getTimeAgo(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 365) {
        return '${(difference.inDays / 365).floor()}y ago';
      } else if (difference.inDays > 30) {
        return '${(difference.inDays / 30).floor()}mo ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }
  
  // Helper method to calculate comment score (upvotes - downvotes)
  int _getCommentScore(Comment comment, CommentsProvider provider) {
    final reactionCounts = provider.getReactionCounts(comment.id ?? 0);
    final upvotes = reactionCounts['upvote'] ?? 0;
    final downvotes = reactionCounts['downvote'] ?? 0;
    return upvotes - downvotes;
  }
  
  /// Build quality rating badge for comment
  Widget _buildQualityBadge(CommentQuality quality) {
    final score = quality.overallScore;
    Color badgeColor;
    IconData icon;
    
    if (score >= 4.5) {
      badgeColor = const Color(0xFF4CAF50); // Green
      icon = Icons.stars_rounded;
    } else if (score >= 3.5) {
      badgeColor = const Color(0xFF2196F3); // Blue
      icon = Icons.star_rounded;
    } else if (score >= 2.5) {
      badgeColor = const Color(0xFFFF9800); // Orange
      icon = Icons.star_half_rounded;
    } else {
      badgeColor = const Color(0xFF9E9E9E); // Grey
      icon = Icons.star_outline_rounded;
    }
    
    return Tooltip(
      message: AICommentRatingService.getRatingDescription(score),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: badgeColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: badgeColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: badgeColor),
            const SizedBox(width: 4),
            Text(
              score.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: badgeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = _currentPost ?? widget.post;
    final commentsProvider = Provider.of<CommentsProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.user?.id ?? 0;

    // Separate parent and reply comments
    final parentComments = commentsProvider.comments
        .where((c) => c.parentCommentId == null)
        .toList();
    
    // Sort parent comments based on selected sort type
    if (_commentSortType == 'pertinence') {
      parentComments.sort((a, b) {
        final aVotes = _getCommentScore(a, commentsProvider);
        final bVotes = _getCommentScore(b, commentsProvider);
        return bVotes.compareTo(aVotes); // Higher score first
      });
    } else {
      // Sort by date (most recent first)
      parentComments.sort((a, b) => b.date.compareTo(a.date));
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Header with text instead of image
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            elevation: 0,
            backgroundColor: AppTheme.primaryColor,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              // Debate Mode Toggle (show if there are enough comments)
              if (commentsProvider.comments.length >= 3)
                _loadingDebate
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      )
                    : IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _debateModeEnabled
                                ? Colors.white.withOpacity(0.3)
                                : Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.psychology_rounded,
                            color: _debateModeEnabled ? const Color(0xFFFFD700) : Colors.white,
                            size: 20,
                          ),
                        ),
                        tooltip: _debateModeEnabled ? 'Exit Debate Mode' : 'Analyze Discussion',
                        onPressed: _toggleDebateMode,
                      ),
              
              // Only show edit/delete buttons if current user is the post owner
              if ((_currentPost ?? widget.post).userId == (Provider.of<AuthProvider>(context, listen: false).user?.id ?? 0)) ...[
                // Edit button
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                  ),
                  onPressed: () {
                    _showEditPostDialog();
                  },
                ),
                // Delete button
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                  ),
                  onPressed: () {
                    _showDeletePostDialog();
                  },
                ),
              ],
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Text(
                      "Your post detail",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Post Content
          SliverToBoxAdapter(
            child: FadeInUp(
              duration: const Duration(milliseconds: 600),
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time and Date at top
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getTimeAgo(post.date.toIso8601String()),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd MMM yyyy').format(post.date),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // User name with avatar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                            child: Icon(
                              Icons.person,
                              color: AppTheme.primaryColor,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          FutureBuilder<String>(
                            future: _getUserName(post.userId),
                            builder: (context, snapshot) {
                              return Text(
                                snapshot.data ?? 'Loading...',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // Title
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Text(
                        post.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3142),
                          height: 1.3,
                        ),
                      ),
                    ),

                    // Description (moved here, right after title)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Text(
                        post.description,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ),

                    // Post Image
                    if (post.imagePath != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            File(post.imagePath!),
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                    // Tags
                    if (post.tags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: post.tags.split(',').map((tag) {
                            // Different colors for different tags
                            Color tagColor;
                            if (tag.trim().toLowerCase() == 'event') {
                              tagColor = Colors.purple;
                            } else if (tag.trim().toLowerCase() == 'popular') {
                              tagColor = Colors.orange;
                            } else {
                              tagColor = AppTheme.primaryColor;
                            }

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: tagColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: tagColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                tag.trim(),
                                style: TextStyle(
                                  color: tagColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                    // Divider
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Divider(
                        height: 1,
                        color: Colors.grey[200],
                      ),
                    ),

                    // Engagement buttons with emojis
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      child: Row(
                        children: [
                          // React button - shows picker
                          Expanded(
                            child: InkWell(
                              onTap: _showReactionPicker,
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  color: _userReactionType != null
                                      ? AppTheme.primaryColor.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: _userReactionType != null
                                      ? Border.all(color: AppTheme.primaryColor, width: 2)
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Show heart icon in red if love reaction, else emoji
                                    if (_userReactionType == 'love')
                                      Icon(
                                        Icons.favorite,
                                        size: 18,
                                        color: Colors.red,
                                      )
                                    else
                                      Text(
                                        _userReactionType != null 
                                            ? _getReactionEmoji(_userReactionType!)
                                            : '👍',
                                        style: TextStyle(
                                          fontSize: _userReactionType != null ? 18 : 16,
                                        ),
                                      ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${_reactionCounts.values.fold<int>(0, (sum, count) => sum + count)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: _userReactionType != null 
                                            ? AppTheme.primaryColor 
                                            : Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Comments
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                // Scroll to comments
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline,
                                      size: 18,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${parentComments.length}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Share
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                // Handle share
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.share_outlined,
                                      size: 18,
                                      color: Colors.grey[700],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Reactions Summary - "Liked by" (Below engagement buttons)
                    if (_reactionCounts.values.fold<int>(0, (sum, count) => sum + count) > 0)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                        child: InkWell(
                          onTap: _showReactionsList,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryColor.withOpacity(0.05),
                                  Colors.white,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.primaryColor.withOpacity(0.15),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Reaction icons stacked
                                SizedBox(
                                  width: 70,
                                  height: 28,
                                  child: Stack(
                                    children: [
                                      ...() {
                                        List<Widget> reactionIcons = [];
                                        int index = 0;
                                        var sortedReactions = _reactionCounts.entries.toList()
                                          ..sort((a, b) => b.value.compareTo(a.value));
                                        
                                        for (var entry in sortedReactions) {
                                          if (entry.value > 0 && index < 3) {
                                            reactionIcons.add(
                                              Positioned(
                                                left: index * 20.0,
                                                child: Container(
                                                  width: 30,
                                                  height: 30,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        Colors.white,
                                                        Colors.grey[50]!,
                                                      ],
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                    ),
                                                    border: Border.all(
                                                      color: Colors.white,
                                                      width: 2.5,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: AppTheme.primaryColor.withOpacity(0.2),
                                                        blurRadius: 8,
                                                        offset: const Offset(0, 3),
                                                        spreadRadius: 1,
                                                      ),
                                                    ],
                                                  ),
                                                  child: Center(
                                                    child: entry.key == 'love'
                                                        ? Icon(
                                                            Icons.favorite,
                                                            size: 16,
                                                            color: Colors.red,
                                                          )
                                                        : Text(
                                                            _getReactionEmoji(entry.key),
                                                            style: TextStyle(fontSize: 16),
                                                          ),
                                                  ),
                                                ),
                                              ),
                                            );
                                            index++;
                                          }
                                        }
                                        return reactionIcons;
                                      }(),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                
                                // "Liked by" text
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                      children: [
                                        TextSpan(
                                          text: 'Liked by ',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        TextSpan(
                                          text: '${_reactionCounts.values.fold<int>(0, (sum, count) => sum + count)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                        TextSpan(
                                          text: _reactionCounts.values.fold<int>(0, (sum, count) => sum + count) == 1 
                                              ? ' person' 
                                              : ' people',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                
                                // Arrow indicator
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Discover Related Articles Suggestion
          SliverToBoxAdapter(
            child: _buildDiscoverSuggestionCard(),
          ),

          // Comments Section Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.chat_bubble_outline,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Comments (${parentComments.length})',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                    ],
                  ),
                  // Buttons row
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // AI Mentor button (shown when no comments)
                      if (parentComments.isEmpty && !_mentorHintGenerated)
                        InkWell(
                      onTap: _loadingMentorHint ? null : () => _generateAIMentorHint(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFFF9800).withOpacity(0.9),
                              const Color(0xFFFF6F00).withOpacity(0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF9800).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_loadingMentorHint)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            else
                              const Icon(
                                Icons.lightbulb_outline,
                                size: 16,
                                color: Colors.white,
                              ),
                            const SizedBox(width: 6),
                            Text(
                              _loadingMentorHint ? 'Generating...' : 'AI Mentor Hint',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                        )
                      else
                        // Sort button
                        InkWell(
                      onTap: () {
                        setState(() {
                          _commentSortType = _commentSortType == 'pertinence' ? 'recent' : 'pertinence';
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor.withOpacity(0.15),
                              AppTheme.primaryColor.withOpacity(0.08),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _commentSortType == 'pertinence' 
                                  ? Icons.trending_up_rounded 
                                  : Icons.access_time_rounded,
                              size: 16,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _commentSortType == 'pertinence' ? 'Pertinence' : 'Plus récents',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Comments List or Debate View
          if (_debateModeEnabled && _debateAnalysis != null)
            // Show Debate View
            SliverFillRemaining(
              child: DebateView(
                debate: _debateAnalysis!,
                onRefresh: _analyzeDebate,
              ),
            )
          else if (commentsProvider.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (parentComments.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 80,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No comments yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Be the first to comment!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final comment = parentComments[index];
                    final replies = commentsProvider.comments
                        .where((c) => c.parentCommentId == comment.id)
                        .toList();
                    
                    // Sort replies based on selected sort type
                    if (_commentSortType == 'pertinence') {
                      replies.sort((a, b) {
                        final aVotes = _getCommentScore(a, commentsProvider);
                        final bVotes = _getCommentScore(b, commentsProvider);
                        return bVotes.compareTo(aVotes); // Higher score first
                      });
                    } else {
                      // Sort by date (most recent first)
                      replies.sort((a, b) => b.date.compareTo(a.date));
                    }
                    
                    return FadeInUp(
                      duration: const Duration(milliseconds: 400),
                      delay: Duration(milliseconds: 50 * index),
                      child: _buildCommentCard(
                        comment,
                        commentsProvider,
                        currentUserId,
                        replies: replies,
                      ),
                    );
                  },
                  childCount: parentComments.length,
                ),
              ),
            ),

          // Bottom spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),

      // Floating Comment Input
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                  child: Icon(
                    Icons.person,
                    color: AppTheme.primaryColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MentionTextField(
                    key: _mainCommentMentionKey,
                    controller: _commentController,
                    hintText: "Write a comment... (type @ to mention)",
                    maxLines: 4,
                    minLines: 1,
                    onMentionsChanged: (mentionedIds) {
                      setState(() {
                        _mainCommentMentions = mentionedIds;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // AI Tutor button
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF9C27B0),
                        Color(0xFF673AB7),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF9C27B0).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Text('🤖', style: TextStyle(fontSize: 18)),
                    onPressed: _openAITutor,
                    tooltip: 'Ask AI Tutor',
                  ),
                ),
                const SizedBox(width: 8),
                // Voice comment button
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF673AB7),
                        Color(0xFF512DA8),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF673AB7).withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: _isProcessingVoice
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.mic, color: Colors.white),
                    onPressed: _isProcessingVoice ? null : _showVoiceRecorder,
                    tooltip: 'Record voice comment',
                  ),
                ),
                const SizedBox(width: 8),
                // Send text button
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withOpacity(0.8),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    onPressed: () => _addComment(_commentController.text),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildCommentCard(
    Comment comment,
    CommentsProvider commentsProvider,
    int currentUserId, {
    List<Comment>? replies,
    bool isReply = false,
  }) {
    final reactionCounts = commentsProvider.getReactionCounts(comment.id ?? 0);
    final upvotes = reactionCounts['upvote'] ?? 0;
    final downvotes = reactionCounts['downvote'] ?? 0;
    final totalVotes = upvotes - downvotes;
    final isAIMentor = comment.userId == AIMentorService.aiMentorUserId;

    return FutureBuilder<String?>(
      future: commentsProvider.getUserCommentReaction(comment.id ?? 0, currentUserId),
      builder: (context, reactionSnapshot) {
        final userReaction = reactionSnapshot.data;

        return Container(
          margin: EdgeInsets.only(
            bottom: isReply ? 10 : 16,
            left: isReply ? 40 : 0,
          ),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: isAIMentor
                ? LinearGradient(
                    colors: [
                      const Color(0xFFFFF3E0),
                      const Color(0xFFFFE0B2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isAIMentor ? null : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isAIMentor ? const Color(0xFFFF9800) : Colors.grey[200]!,
              width: isAIMentor ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isAIMentor
                    ? const Color(0xFFFF9800).withOpacity(0.15)
                    : Colors.black.withOpacity(0.04),
                blurRadius: isAIMentor ? 12 : 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info - Clean and Simple (Special styling for AI Mentor)
              Row(
                children: [
                  CircleAvatar(
                    radius: isReply ? 16 : 18,
                    backgroundColor: isAIMentor
                        ? const Color(0xFFFF9800)
                        : AppTheme.primaryColor.withOpacity(0.1),
                    child: Icon(
                      isAIMentor ? Icons.lightbulb : Icons.person,
                      color: isAIMentor ? Colors.white : AppTheme.primaryColor,
                      size: isReply ? 16 : 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FutureBuilder<String>(
                          future: _getUserName(comment.userId),
                          builder: (context, snapshot) {
                            return Row(
                              children: [
                                Text(
                                  snapshot.data ?? 'Loading...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isAIMentor
                                        ? const Color(0xFFE65100)
                                        : const Color(0xFF1A1A1A),
                                  ),
                                ),
                                if (isAIMentor) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFF9800),
                                          Color(0xFFFF6F00),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'AI',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getTimeAgo(comment.date),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Edit/Delete menu for user's own comments (but not AI Mentor)
                  if (comment.userId == currentUserId && !isAIMentor)
                    PopupMenuButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.more_horiz, color: Colors.grey[600], size: 20),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, color: Colors.blue, size: 18),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: Colors.red, size: 18),
                              SizedBox(width: 8),
                              Text('Delete'),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditCommentDialog(comment, commentsProvider);
                        } else if (value == 'delete') {
                          _showDeleteCommentDialog(comment, commentsProvider);
                        }
                      },
                    ),
                  // Quality Rating Badge
                  if (comment.id != null && _commentRatings.containsKey(comment.id!) && !isAIMentor)
                    _buildQualityBadge(_commentRatings[comment.id!]!),
                ],
              ),
              const SizedBox(height: 12),

              // Voice Player (if comment has voice)
              if (comment.hasVoice && comment.id != null && _voiceComments.containsKey(comment.id)) ...[
                VoicePlayerWidget(
                  voiceComment: _voiceComments[comment.id]!,
                  isCompact: true,
                ),
                const SizedBox(height: 12),
              ],
              
              // Comment Content - Simple
              Text(
                comment.content,
                style: TextStyle(
                  fontSize: 14,
                  color: isAIMentor ? const Color(0xFF424242) : Colors.grey[800],
                  height: 1.5,
                ),
              ),
              
              // Voice tags (extracted keywords)
              if (comment.hasVoice && comment.id != null && _voiceComments.containsKey(comment.id)) ...[
                if (_voiceComments[comment.id]!.extractedTags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _voiceComments[comment.id]!.extractedTags
                        .map((tag) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF673AB7).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF673AB7).withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                tag,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF673AB7),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ],
              
              // AI Mentor regenerate button
              if (isAIMentor) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: _loadingMentorHint ? null : () => _generateAIMentorHint(regenerate: true),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFF9800).withOpacity(0.15),
                          const Color(0xFFFF6F00).withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFFF9800).withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: const Color(0xFFFF6F00),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _loadingMentorHint ? 'Generating...' : 'Generate more hints ✨',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFE65100),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 16),

              // Vote buttons and actions - Modern minimal (hidden for AI Mentor)
              if (!isAIMentor)
              Row(
                children: [
                  // Upvote
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        commentsProvider.toggleCommentReaction(
                          comment.id!,
                          comment.postId,
                          currentUserId,
                          'upvote',
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: userReaction == 'upvote'
                              ? Colors.green.withOpacity(0.1)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.arrow_upward_rounded,
                              size: 16,
                              color: userReaction == 'upvote'
                                  ? Colors.green
                                  : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$upvotes',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: userReaction == 'upvote'
                                    ? Colors.green
                                    : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Downvote
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        commentsProvider.toggleCommentReaction(
                          comment.id!,
                          comment.postId,
                          currentUserId,
                          'downvote',
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: userReaction == 'downvote'
                              ? Colors.red.withOpacity(0.1)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.arrow_downward_rounded,
                              size: 16,
                              color: userReaction == 'downvote'
                                  ? Colors.red
                                  : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$downvotes',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: userReaction == 'downvote'
                                    ? Colors.red
                                    : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Total score
                  if (totalVotes != 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: totalVotes > 0
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${totalVotes > 0 ? '+' : ''}$totalVotes',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: totalVotes > 0 ? Colors.blue : Colors.orange,
                        ),
                      ),
                    ),
                ],
              ),

              // Reply and View Replies buttons row (only for parent comments, not AI Mentor)
              if (!isReply && !isAIMentor)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      // View Replies button (only if there are replies)
                      if (replies != null && replies.isNotEmpty)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _showReplies[comment.id!] = !(_showReplies[comment.id!] ?? false);
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _showReplies[comment.id] == true
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    size: 18,
                                    color: AppTheme.primaryColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _showReplies[comment.id] == true
                                        ? 'Masquer les réponses'
                                        : 'Voir les réponses (${replies.length})',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      
                      // Spacer between buttons
                      if (replies != null && replies.isNotEmpty)
                        const SizedBox(width: 8),
                      
                      // Reply button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _showReplyInput[comment.id!] = !(_showReplyInput[comment.id!] ?? false);
                              if (_showReplyInput[comment.id!] == true) {
                                _replyControllers[comment.id!] = TextEditingController();
                                _replyMentionKeys[comment.id!] = GlobalKey<MentionTextFieldState>();
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.reply_rounded,
                                  size: 16,
                                  color: AppTheme.primaryColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Reply',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Reply Input - Simple
              if (_showReplyInput[comment.id] == true && !isReply)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        child: Icon(
                          Icons.person,
                          color: AppTheme.primaryColor,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: MentionTextField(
                          key: _replyMentionKeys[comment.id!],
                          controller: _replyControllers[comment.id!]!,
                          hintText: 'Write a reply... (type @ to mention)',
                          maxLines: 3,
                          minLines: 1,
                          onMentionsChanged: (mentionedIds) {
                            setState(() {
                              _replyMentions[comment.id!] = mentionedIds;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            final text = _replyControllers[comment.id!]?.text ?? '';
                            if (text.isNotEmpty) {
                              _addComment(text, parentCommentId: comment.id);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),

              // Replies (only shown when _showReplies is true)
              if (replies != null && replies.isNotEmpty && _showReplies[comment.id] == true)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    children: replies.map((reply) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: _buildCommentCard(
                          reply,
                          commentsProvider,
                          currentUserId,
                          isReply: true,
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
  
  String _getReactionEmoji(String reactionType) {
    switch (reactionType) {
      case 'upvote':
        return '👍';
      case 'downvote':
        return '👎';
      case 'like':
        return '👍';
      case 'dislike':
        return '👎';
      case 'love':
        return '❤️';
      case 'care':
        return '🤗';
      case 'haha':
        return '😂';
      case 'wow':
        return '😮';
      case 'sad':
        return '😢';
      case 'angry':
        return '😠';
      default:
        return '👍';
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
