class Lesson {
  final int? id;
  final int courseId;
  final String title;
  final String content;
  final int orderIndex;
  final String? createdAt;
  final int? duration;
  final String? pdfUrl; // ✅ Nouveau champ : lien du PDF

  Lesson({
    this.id,
    required this.courseId,
    required this.title,
    required this.content,
    this.orderIndex = 0,
    this.createdAt,
    this.duration,
    this.pdfUrl, // ✅ ajouté
  });

  factory Lesson.fromMap(Map<String, dynamic> map) {
    return Lesson(
      id: map['id'] as int?,
      courseId: map['course_id'] as int,
      title: map['title'] as String,
      content: map['content'] as String,
      orderIndex: (map['order_index'] ?? 0) as int,
      createdAt: map['created_at'] as String?,
      duration: map['duration'] as int?,
      pdfUrl: map['pdf_url'] as String?, // ✅ ajouté
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'course_id': courseId,
    'title': title,
    'content': content,
    'order_index': orderIndex,
    'created_at': createdAt,
    'duration': duration,
    'pdf_url': pdfUrl, // ✅ ajouté
  };
}
