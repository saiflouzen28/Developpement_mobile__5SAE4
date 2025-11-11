class Reaction {
  int? id;               // Primary key
  String targetType;     // 'post' or 'comment'
  int targetId;          // ID of the post or comment
  int userId;            // ID of the user who reacted
  String reactionType;   // 'like', 'love', 'care', 'haha', 'wow', 'sad', 'angry'

  Reaction({
    this.id,
    required this.targetType,
    required this.targetId,
    required this.userId,
    required this.reactionType,
  });

  /// Convert Reaction object to Map for DB storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'targetType': targetType,
      'targetId': targetId,
      'userId': userId,
      'reactionType': reactionType,
    };
  }

  /// Convert Map from DB to Reaction object
  factory Reaction.fromMap(Map<String, dynamic> map) {
    return Reaction(
      id: map['id'] as int?,
      targetType: map['targetType'] ?? 'post',
      targetId: map['targetId'] as int,
      userId: map['userId'] as int,
      reactionType: map['reactionType'] ?? 'like',
    );
  }
}
