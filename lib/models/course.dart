class Course {
  int? id;
  String title;
  String? description;
  String filePath;
  int createdAt;

  Course({
    this.id,
    required this.title,
    this.description,
    required this.filePath,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'file_path': filePath,
    'created_at': createdAt,
  };

  factory Course.fromMap(Map<String, dynamic> map) => Course(
    id: map['id'] as int?,
    title: map['title'] ?? '',
    description: map['description'],
    filePath: map['file_path'],
    createdAt: map['created_at'] as int,
  );
}
