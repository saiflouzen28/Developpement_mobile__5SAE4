import 'course.dart';
class Pack {
  int? id;
  String title;
  String? description;
  double price;
  int durationDays;
  int createdAt;
  int? updatedAt;
  List<Course> courses; // ✅ liste des cours associés

  Pack({
    this.id,
    required this.title,
    this.description,
    required this.price,
    this.durationDays = 365,
    required this.createdAt,
    this.updatedAt,
    this.courses = const [], // par défaut vide
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'price': price,
    'duration_days': durationDays,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  factory Pack.fromMap(Map<String, dynamic> m) => Pack(
    id: m['id'] as int?,
    title: m['title'],
    description: m['description'],
    price: (m['price'] as num).toDouble(),
    durationDays: m['duration_days'] as int,
    createdAt: m['created_at'] as int,
    updatedAt: m['updated_at'] as int?,
  );
}
