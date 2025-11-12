class Quiz {
  final int? id;
  final String title;
  final String? description;
  final int totalQuestions;
  final int durationMinutes;
  final String? category;       // New field
  final String? difficulty;     // New field
  final int? createdBy;
  final DateTime? createdAt;

  Quiz({
    this.id,
    required this.title,
    this.description,
    required this.totalQuestions,
    required this.durationMinutes,
    this.category,
    this.difficulty,
    this.createdBy,
    this.createdAt,
  });

  // Convert a Quiz object into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'total_questions': totalQuestions,
      'duration_minutes': durationMinutes,
      'category': category,
      'difficulty': difficulty,
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  // Convert a Map into a Quiz object
  factory Quiz.fromMap(Map<String, dynamic> map) {
    return Quiz(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      totalQuestions: map['total_questions'],
      durationMinutes: map['duration_minutes'],
      category: map['category'],
      difficulty: map['difficulty'],
      createdBy: map['created_by'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
    );
  }
}
