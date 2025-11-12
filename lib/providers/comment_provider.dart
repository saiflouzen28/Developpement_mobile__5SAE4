import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/comment_model.dart';
import '../models/reaction_model.dart';

class CommentsProvider with ChangeNotifier {
  List<Comment> _comments = [];
  List<Comment> _filteredComments = [];
  bool _isLoading = false;
  String? _error;
  
  // Store reactions for comments
  Map<int, List<Reaction>> _commentReactions = {};
  Map<int, Map<String, int>> _reactionCounts = {};

  List<Comment> get comments => _filteredComments;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Get reactions for a specific comment
  List<Reaction> getCommentReactions(int commentId) {
    return _commentReactions[commentId] ?? [];
  }
  
  // Get reaction counts for a comment
  Map<String, int> getReactionCounts(int commentId) {
    return _reactionCounts[commentId] ?? {};
  }

  // Load comments for a specific post
  Future<void> loadComments(int postId) async {
    _setLoading(true);
    _setError(null);
    try {
      final commentsData = await DatabaseHelper.instance.getCommentsByPost(postId);
      _comments = commentsData.map((e) => Comment.fromMap(e)).toList();
      _filteredComments = List.from(_comments);
      
      // Load reactions for each comment
      for (var comment in _comments) {
        if (comment.id != null) {
          await _loadCommentReactions(comment.id!);
        }
      }
      
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load comments: ${e.toString()}');
      _setLoading(false);
    }
  }
  
  // Load reactions for a specific comment
  Future<void> _loadCommentReactions(int commentId) async {
    try {
      final reactionsData = await DatabaseHelper.instance.getReactionsByTarget('comment', commentId);
      _commentReactions[commentId] = reactionsData.map((e) => Reaction.fromMap(e)).toList();
      
      // Get reaction counts
      _reactionCounts[commentId] = await DatabaseHelper.instance.getReactionCounts('comment', commentId);
    } catch (e) {
      print('Failed to load reactions for comment $commentId: $e');
    }
  }

  Future<void> refreshComments(int postId) async {
    await loadComments(postId);
  }

  // Add a comment
  Future<int> addComment(Comment comment) async {
    final commentId = await DatabaseHelper.instance.addComment(comment.toMap());
    if (commentId > 0) {
      await loadComments(comment.postId);
      return commentId;
    }
    return -1; // Return -1 to indicate failure
  }

  // Update a comment
  Future<bool> updateComment(Comment comment) async {
    try {
      final success = await DatabaseHelper.instance.updateComment(comment.toMap());
      if (success) {
        await loadComments(comment.postId);
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to update comment: ${e.toString()}');
      return false;
    }
  }

  // Delete a comment
  Future<bool> deleteComment(Comment comment) async {
    try {
      final success = await DatabaseHelper.instance.deleteComment(comment.id!);
      if (success) {
        await loadComments(comment.postId);
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to delete comment: ${e.toString()}');
      return false;
    }
  }

  // Toggle reaction on a comment
  Future<bool> toggleCommentReaction(int commentId, int postId, int userId, String reactionType) async {
    try {
      final success = await DatabaseHelper.instance.toggleReaction(
        'comment',
        commentId,
        userId,
        reactionType,
      );
      if (success) {
        // Reload reactions for this comment
        await _loadCommentReactions(commentId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to react: ${e.toString()}');
      return false;
    }
  }
  
  // Get user's reaction for a comment
  Future<String?> getUserCommentReaction(int commentId, int userId) async {
    try {
      final reaction = await DatabaseHelper.instance.getUserReaction('comment', commentId, userId);
      return reaction?['reactionType'] as String?;
    } catch (e) {
      return null;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
