class Course {
  final int? id;
  final String title;
  final String description;
  final String? imageUrl;
  final String category;
  final int lessonsCount;
  final String? createdAt;
  final String? level; // ✅ ajouté pour corriger l’erreur

  Course({
    this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.category,
    this.lessonsCount = 0,
    this.createdAt,
    this.level, // ✅ ajouté
  });

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String,
      imageUrl: map['image_url'] as String?,
      category: map['category'] as String,
      lessonsCount: (map['lessons_count'] ?? 0) as int,
      createdAt: map['created_at'] as String?,
      level: map['level'] as String?, // ✅ si jamais on ajoute une colonne plus tard
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'image_url': imageUrl,
    'category': category,
    'created_at': createdAt,
    'level': level, // ✅ ajouté
  };
}
