class Comment {
  int? id;
  int postId;             // Reference to the post
  int? parentCommentId;   // For subcomments (nullable)
  int userId;             // ID of the user who made the comment
  String content;         // Comment text
  String date;            // ISO string (e.g., 2025-10-19T12:30:00Z)
  String? mentionedUserIds; // Comma-separated user IDs (e.g., "1,5,10")
  double? qualityRating;  // AI-evaluated quality score (0.0-5.0)
  bool hasVoice;          // Whether this comment has a voice recording
  int? voiceCommentId;    // Reference to voice_comments table

  Comment({
    this.id,
    required this.postId,
    this.parentCommentId,
    required this.userId,
    required this.content,
    required this.date,
    this.mentionedUserIds,
    this.qualityRating,
    this.hasVoice = false,
    this.voiceCommentId,
  });

  // Convert map from DB to Comment object
  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'] as int?,
      postId: map['postId'] as int,
      parentCommentId: map['parentCommentId'] as int?,
      userId: map['userId'] as int,
      content: map['content'] as String,
      date: map['date'] as String,
      mentionedUserIds: map['mentionedUserIds'] as String?,
      qualityRating: map['qualityRating'] != null 
          ? (map['qualityRating'] as num).toDouble() 
          : null,
      hasVoice: map['hasVoice'] == 1,
      voiceCommentId: map['voiceCommentId'] as int?,
    );
  }

  // Convert Comment object to map for DB
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'postId': postId,
      'parentCommentId': parentCommentId,
      'userId': userId,
      'content': content,
      'date': date,
      'mentionedUserIds': mentionedUserIds,
      'qualityRating': qualityRating,
      'hasVoice': hasVoice ? 1 : 0,
      'voiceCommentId': voiceCommentId,
    };
  }

  // Get list of mentioned user IDs
  List<int> getMentionedUserIds() {
    if (mentionedUserIds == null || mentionedUserIds!.isEmpty) {
      return [];
    }
    return mentionedUserIds!.split(',').map((id) => int.parse(id)).toList();
  }
}
