class AppNotification {
  final int? id;
  final int userId; // User who will receive the notification
  final int fromUserId; // User who triggered the notification
  final String type; // 'comment', 'reply', 'reaction', etc.
  final int? postId;
  final int? commentId;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    this.id,
    required this.userId,
    required this.fromUserId,
    required this.type,
    this.postId,
    this.commentId,
    required this.message,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'fromUserId': fromUserId,
      'type': type,
      'postId': postId,
      'commentId': commentId,
      'message': message,
      'isRead': isRead ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as int?,
      userId: map['userId'] as int,
      fromUserId: map['fromUserId'] as int,
      type: map['type'] as String,
      postId: map['postId'] as int?,
      commentId: map['commentId'] as int?,
      message: map['message'] as String,
      isRead: (map['isRead'] as int) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  AppNotification copyWith({
    int? id,
    int? userId,
    int? fromUserId,
    String? type,
    int? postId,
    int? commentId,
    String? message,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fromUserId: fromUserId ?? this.fromUserId,
      type: type ?? this.type,
      postId: postId ?? this.postId,
      commentId: commentId ?? this.commentId,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
