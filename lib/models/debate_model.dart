class DebateAnalysis {
  final String postId;
  final List<DebateArgument> forArguments;
  final List<DebateArgument> againstArguments;
  final List<DebateArgument> neutralArguments;
  final String summary;
  final String verdict;
  final DebateContributor? topContributor;
  final DateTime analyzedAt;

  DebateAnalysis({
    required this.postId,
    required this.forArguments,
    required this.againstArguments,
    required this.neutralArguments,
    required this.summary,
    required this.verdict,
    this.topContributor,
    required this.analyzedAt,
  });

  factory DebateAnalysis.fromJson(Map<String, dynamic> json) {
    return DebateAnalysis(
      postId: json['postId'] ?? '',
      forArguments: (json['forArguments'] as List<dynamic>?)
          ?.map((e) => DebateArgument.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      againstArguments: (json['againstArguments'] as List<dynamic>?)
          ?.map((e) => DebateArgument.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      neutralArguments: (json['neutralArguments'] as List<dynamic>?)
          ?.map((e) => DebateArgument.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      summary: json['summary'] ?? '',
      verdict: json['verdict'] ?? '',
      topContributor: json['topContributor'] != null
          ? DebateContributor.fromJson(json['topContributor'] as Map<String, dynamic>)
          : null,
      analyzedAt: DateTime.parse(json['analyzedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'postId': postId,
      'forArguments': forArguments.map((e) => e.toJson()).toList(),
      'againstArguments': againstArguments.map((e) => e.toJson()).toList(),
      'neutralArguments': neutralArguments.map((e) => e.toJson()).toList(),
      'summary': summary,
      'verdict': verdict,
      'topContributor': topContributor?.toJson(),
      'analyzedAt': analyzedAt.toIso8601String(),
    };
  }
}

class DebateArgument {
  final int commentId;
  final String userName;
  final String content;
  final String stance; // 'for', 'against', 'neutral'
  final double qualityScore; // 0-10
  final String reasoning;

  DebateArgument({
    required this.commentId,
    required this.userName,
    required this.content,
    required this.stance,
    required this.qualityScore,
    required this.reasoning,
  });

  factory DebateArgument.fromJson(Map<String, dynamic> json) {
    return DebateArgument(
      commentId: json['commentId'] ?? 0,
      userName: json['userName'] ?? '',
      content: json['content'] ?? '',
      stance: json['stance'] ?? 'neutral',
      qualityScore: (json['qualityScore'] ?? 0.0).toDouble(),
      reasoning: json['reasoning'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'commentId': commentId,
      'userName': userName,
      'content': content,
      'stance': stance,
      'qualityScore': qualityScore,
      'reasoning': reasoning,
    };
  }
}

class DebateContributor {
  final int userId;
  final String userName;
  final double contributionScore;
  final String contributionReason;

  DebateContributor({
    required this.userId,
    required this.userName,
    required this.contributionScore,
    required this.contributionReason,
  });

  factory DebateContributor.fromJson(Map<String, dynamic> json) {
    return DebateContributor(
      userId: json['userId'] ?? 0,
      userName: json['userName'] ?? '',
      contributionScore: (json['contributionScore'] ?? 0.0).toDouble(),
      contributionReason: json['contributionReason'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'contributionScore': contributionScore,
      'contributionReason': contributionReason,
    };
  }
}
