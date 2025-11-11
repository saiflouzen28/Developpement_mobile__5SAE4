class PackCourse {
  int? id;
  int packId;
  int courseId;

  PackCourse({this.id, required this.packId, required this.courseId});

  Map<String, dynamic> toMap() => {
    'id': id,
    'pack_id': packId,
    'course_id': courseId,
  };

  factory PackCourse.fromMap(Map<String, dynamic> m) => PackCourse(
    id: m['id'] as int?,
    packId: m['pack_id'] as int,
    courseId: m['course_id'] as int,
  );
}
