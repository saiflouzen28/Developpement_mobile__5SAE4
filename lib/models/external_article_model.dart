/// External Article Model
/// Represents an article fetched from external sources (RSS feeds)
class ExternalArticle {
  final int? id;
  final String title;
  final String description;
  final String url;
  final String source; // e.g., "FreeCodeCamp", "Medium", "Dev.to"
  final String? imageUrl;
  final String? publishDate;
  final String fetchedAt;
  final bool isRead;
  final bool isFavorite;

  ExternalArticle({
    this.id,
    required this.title,
    required this.description,
    required this.url,
    required this.source,
    this.imageUrl,
    this.publishDate,
    required this.fetchedAt,
    this.isRead = false,
    this.isFavorite = false,
  });

  /// Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'url': url,
      'source': source,
      'imageUrl': imageUrl,
      'publishDate': publishDate,
      'fetchedAt': fetchedAt,
      'isRead': isRead ? 1 : 0,
      'isFavorite': isFavorite ? 1 : 0,
    };
  }

  /// Create from Map (from database)
  factory ExternalArticle.fromMap(Map<String, dynamic> map) {
    return ExternalArticle(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String,
      url: map['url'] as String,
      source: map['source'] as String,
      imageUrl: map['imageUrl'] as String?,
      publishDate: map['publishDate'] as String?,
      fetchedAt: map['fetchedAt'] as String,
      isRead: (map['isRead'] as int) == 1,
      isFavorite: (map['isFavorite'] as int) == 1,
    );
  }

  /// Create from API/RSS response
  factory ExternalArticle.fromJson(Map<String, dynamic> json) {
    return ExternalArticle(
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      url: json['url'] as String,
      source: json['source'] as String,
      imageUrl: json['imageUrl'] as String?,
      publishDate: json['publishDate'] as String?,
      fetchedAt: json['fetchedAt'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  /// Copy with modifications
  ExternalArticle copyWith({
    int? id,
    String? title,
    String? description,
    String? url,
    String? source,
    String? imageUrl,
    String? publishDate,
    String? fetchedAt,
    bool? isRead,
    bool? isFavorite,
  }) {
    return ExternalArticle(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      url: url ?? this.url,
      source: source ?? this.source,
      imageUrl: imageUrl ?? this.imageUrl,
      publishDate: publishDate ?? this.publishDate,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      isRead: isRead ?? this.isRead,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  /// Get formatted publish date
  String getFormattedDate() {
    if (publishDate == null || publishDate!.isEmpty) {
      return 'Unknown date';
    }

    try {
      final date = DateTime.parse(publishDate!);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          return '${difference.inMinutes}m ago';
        }
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else if (difference.inDays < 30) {
        return '${(difference.inDays / 7).floor()}w ago';
      } else {
        return '${(difference.inDays / 30).floor()}mo ago';
      }
    } catch (e) {
      return publishDate ?? 'Unknown date';
    }
  }

  /// Get source icon emoji
  String getSourceIcon() {
    switch (source.toLowerCase()) {
      case 'freecodecamp':
        return '🔥';
      case 'medium':
        return '📝';
      case 'dev.to':
        return '💻';
      case 'hashnode':
        return '📰';
      case 'coursera':
        return '🎓';
      case 'openclassrooms':
        return '📚';
      default:
        return '🌐';
    }
  }

  /// Get source color
  String getSourceColor() {
    switch (source.toLowerCase()) {
      case 'freecodecamp':
        return '#0a0a23';
      case 'medium':
        return '#00ab6c';
      case 'dev.to':
        return '#0a0a0a';
      case 'hashnode':
        return '#2962ff';
      case 'coursera':
        return '#0056d2';
      case 'openclassrooms':
        return '#7451eb';
      default:
        return '#6c757d';
    }
  }
}
