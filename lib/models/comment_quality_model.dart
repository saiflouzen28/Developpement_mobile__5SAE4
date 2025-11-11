/// Model for storing comment quality evaluation
class CommentQuality {
  final int commentId;
  final double relevance;       // 0-5: Is it related to the post topic?
  final double clarity;         // 0-5: Is it clearly written?
  final double constructiveness; // 0-5: Does it add value?
  final double tone;            // 0-5: Is it respectful/neutral?
  final double overallScore;    // Average of all criteria (0-5)
  final DateTime evaluatedAt;

  CommentQuality({
    required this.commentId,
    required this.relevance,
    required this.clarity,
    required this.constructiveness,
    required this.tone,
    required this.overallScore,
    DateTime? evaluatedAt,
  }) : evaluatedAt = evaluatedAt ?? DateTime.now();

  // Calculate overall score from criteria
  factory CommentQuality.fromCriteria({
    required int commentId,
    required double relevance,
    required double clarity,
    required double constructiveness,
    required double tone,
  }) {
    // Weighted average: Relevance (40%), Clarity (20%), Constructiveness (20%), Tone (20%)
    final overallScore = (relevance * 0.4) + 
                         (clarity * 0.2) + 
                         (constructiveness * 0.2) + 
                         (tone * 0.2);
    
    return CommentQuality(
      commentId: commentId,
      relevance: relevance,
      clarity: clarity,
      constructiveness: constructiveness,
      tone: tone,
      overallScore: overallScore,
    );
  }

  /// Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'commentId': commentId,
      'relevance': relevance,
      'clarity': clarity,
      'constructiveness': constructiveness,
      'tone': tone,
      'overallScore': overallScore,
      'evaluatedAt': evaluatedAt.toIso8601String(),
    };
  }

  /// Create from database map
  factory CommentQuality.fromMap(Map<String, dynamic> map) {
    return CommentQuality(
      commentId: map['commentId'] as int,
      relevance: (map['relevance'] as num).toDouble(),
      clarity: (map['clarity'] as num).toDouble(),
      constructiveness: (map['constructiveness'] as num).toDouble(),
      tone: (map['tone'] as num).toDouble(),
      overallScore: (map['overallScore'] as num).toDouble(),
      evaluatedAt: DateTime.tryParse(map['evaluatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  /// Get quality level as a string
  String get qualityLevel {
    if (overallScore >= 4.5) return 'Excellent';
    if (overallScore >= 3.5) return 'Good';
    if (overallScore >= 2.5) return 'Average';
    if (overallScore >= 1.5) return 'Below Average';
    return 'Poor';
  }

  /// Get emoji representation
  String get emoji {
    if (overallScore >= 4.5) return '🌟';
    if (overallScore >= 3.5) return '✨';
    if (overallScore >= 2.5) return '⭐';
    if (overallScore >= 1.5) return '💫';
    return '⚪';
  }

  /// Convert to JSON for API calls
  Map<String, dynamic> toJson() => toMap();

  /// Create from JSON response
  factory CommentQuality.fromJson(Map<String, dynamic> json) => CommentQuality.fromMap(json);
}
