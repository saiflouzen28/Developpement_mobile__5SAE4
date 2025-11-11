import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/course.dart';


class CourseRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insertCourse(Course course) async {
    final db = await _dbHelper.database;
    return await db.insert('courses', course.toMap());
  }

  Future<List<Course>> getAllCourses() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('courses');
    return List.generate(maps.length, (i) => Course.fromMap(maps[i]));
  }

  Future<int> updateCourse(Course course) async {
    final db = await _dbHelper.database;
    return await db.update(
      'courses',
      course.toMap(),
      where: 'id = ?',
      whereArgs: [course.id],
    );
  }

  Future<int> deleteCourse(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'courses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Course?> getCourseById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> result =
    await db.query('courses', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return Course.fromMap(result.first);
    }
    return null;
  }
}
