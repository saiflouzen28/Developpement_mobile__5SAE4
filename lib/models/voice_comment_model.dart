/// Voice Comment Model - Extends comment with voice capabilities
class VoiceComment {
  final int? id;
  final int commentId;
  final String audioUrl; // Local or remote URL
  final String transcription;
  final int duration; // Duration in seconds
  final List<String> extractedTags; // Auto-extracted keywords
  final String? tone; // Detected tone: positive, neutral, negative, questioning
  final DateTime recordedAt;
  final double? waveformData; // For audio visualization (simplified)

  VoiceComment({
    this.id,
    required this.commentId,
    required this.audioUrl,
    required this.transcription,
    required this.duration,
    this.extractedTags = const [],
    this.tone,
    required this.recordedAt,
    this.waveformData,
  });

  factory VoiceComment.fromMap(Map<String, dynamic> map) {
    return VoiceComment(
      id: map['id'] as int?,
      commentId: map['commentId'] as int,
      audioUrl: map['audioUrl'] as String,
      transcription: map['transcription'] as String,
      duration: map['duration'] as int,
      extractedTags: map['extractedTags'] != null 
          ? (map['extractedTags'] as String).split(',').where((tag) => tag.isNotEmpty).toList()
          : [],
      tone: map['tone'] as String?,
      recordedAt: DateTime.parse(map['recordedAt'] as String),
      waveformData: map['waveformData'] as double?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'commentId': commentId,
      'audioUrl': audioUrl,
      'transcription': transcription,
      'duration': duration,
      'extractedTags': extractedTags.join(','),
      'tone': tone,
      'recordedAt': recordedAt.toIso8601String(),
      'waveformData': waveformData,
    };
  }

  VoiceComment copyWith({
    int? id,
    int? commentId,
    String? audioUrl,
    String? transcription,
    int? duration,
    List<String>? extractedTags,
    String? tone,
    DateTime? recordedAt,
    double? waveformData,
  }) {
    return VoiceComment(
      id: id ?? this.id,
      commentId: commentId ?? this.commentId,
      audioUrl: audioUrl ?? this.audioUrl,
      transcription: transcription ?? this.transcription,
      duration: duration ?? this.duration,
      extractedTags: extractedTags ?? this.extractedTags,
      tone: tone ?? this.tone,
      recordedAt: recordedAt ?? this.recordedAt,
      waveformData: waveformData ?? this.waveformData,
    );
  }

  /// Get formatted duration (e.g., "2:35")
  String get formattedDuration {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get tone emoji
  String get toneEmoji {
    switch (tone?.toLowerCase()) {
      case 'positive':
      case 'excited':
      case 'happy':
        return '😊';
      case 'questioning':
      case 'curious':
        return '🤔';
      case 'negative':
      case 'frustrated':
        return '😟';
      case 'neutral':
      default:
        return '💬';
    }
  }

  /// Get tone color
  String get toneColorHex {
    switch (tone?.toLowerCase()) {
      case 'positive':
      case 'excited':
      case 'happy':
        return '#4CAF50'; // Green
      case 'questioning':
      case 'curious':
        return '#2196F3'; // Blue
      case 'negative':
      case 'frustrated':
        return '#FF9800'; // Orange
      case 'neutral':
      default:
        return '#9E9E9E'; // Grey
    }
  }
}

/// Playlist item for "Play All" feature
class VoicePlaylistItem {
  final VoiceComment voiceComment;
  final String authorName;
  final String commentContent;
  final bool isReply;
  final int position; // Position in playlist

  VoicePlaylistItem({
    required this.voiceComment,
    required this.authorName,
    required this.commentContent,
    this.isReply = false,
    required this.position,
  });

  String get displayTitle {
    final prefix = isReply ? 'Reply' : 'Comment';
    return '$prefix by $authorName';
  }
}
