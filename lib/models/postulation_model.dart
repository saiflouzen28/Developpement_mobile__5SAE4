import 'package:intl/intl.dart';

class Post {
  final int? id;              // Unique ID
  final String title;         // Post title
  final String description;   // Post body
  final String? imagePath;    // Optional image
  final int userId;           // Reference to user
  final DateTime date;        // Creation date
  final String tags;          // Comma-separated or single tag
  bool isFavorite;            // Favorite flag

  Post({
    this.id,
    required this.title,
    required this.description,
    this.imagePath,
    required this.userId,
    DateTime? date,
    this.tags = '',
    this.isFavorite = false,
  }) : date = date ?? DateTime.now();

  /// Convert Post object to Map for DB storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imagePath': imagePath,
      'userId': userId,
      'date': date.toIso8601String(),
      'tags': tags,
      'isFavorite': isFavorite ? 1 : 0,
    };
  }

  /// Convert Map from DB to Post object
  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'] as int?,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imagePath: map['imagePath'],
      userId: map['userId'] is int
          ? map['userId']
          : int.tryParse(map['userId'].toString()) ?? 0,
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      tags: map['tags'] ?? '',
      isFavorite: (map['isFavorite'] ?? 0) == 1,
    );
  }

  /// Format date nicely (e.g., 19 Oct 2025)
  String get formattedDate => DateFormat('dd MMM yyyy').format(date);
}
