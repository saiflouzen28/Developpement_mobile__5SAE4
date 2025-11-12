import 'dart:convert';

class Review {
  final int rating; // 1..5
  final String? comment;
  final DateTime createdAt;

  Review({
    required this.rating,
    this.comment,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'rating': rating,
    'comment': comment,
    'created_at': createdAt.toIso8601String(),
  };

  factory Review.fromMap(Map<String, dynamic> m) => Review(
    rating: (m['rating'] as num).toInt(),
    comment: m['comment'] as String?,
    createdAt: DateTime.tryParse(m['created_at'] ?? '') ?? DateTime.now(),
  );

  static String encodeList(List<Review> items) =>
      jsonEncode(items.map((e) => e.toMap()).toList());

  static List<Review> decodeList(String jsonStr) {
    final list = (jsonDecode(jsonStr) as List).cast<Map<String, dynamic>>();
    return list.map((m) => Review.fromMap(m)).toList();
  }
}
