import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/pack.dart';
import '../models/course.dart';
import '../models/pack_course.dart';

class PackRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// 🔹 Créer un pack et lui associer des cours
  Future<int> insertPack(Pack pack, {List<int>? courseIds}) async {
    final db = await _dbHelper.database;
    return await db.transaction<int>((txn) async {
      final packId = await txn.insert(
        'pack',
        pack.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (courseIds != null && courseIds.isNotEmpty) {
        final batch = txn.batch();
        for (final cId in courseIds) {
          batch.insert(
            'pack_course',
            {'pack_id': packId, 'course_id': cId},
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
        await batch.commit(noResult: true);
      }

      return packId;
    });
  }

  /// 🔹 Mettre à jour un pack et ses relations
  Future<int> updatePack(Pack pack, {List<int>? courseIds}) async {
    final db = await _dbHelper.database;
    return await db.transaction<int>((txn) async {
      final updated = await txn.update(
        'pack',
        pack.toMap(),
        where: 'id = ?',
        whereArgs: [pack.id],
      );

      if (courseIds != null) {
        // Supprimer les relations existantes puis réinsérer
        await txn.delete('pack_course', where: 'pack_id = ?', whereArgs: [pack.id]);
        final batch = txn.batch();
        for (final cId in courseIds) {
          batch.insert(
            'pack_course',
            {'pack_id': pack.id, 'course_id': cId},
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
        await batch.commit(noResult: true);
      }

      return updated;
    });
  }

  /// 🔹 Supprimer un pack (et ses liaisons)
  Future<int> deletePack(int id) async {
    final db = await _dbHelper.database;
    // Si pas de ON DELETE CASCADE configuré, on nettoie manuellement
    await db.delete('pack_course', where: 'pack_id = ?', whereArgs: [id]);
    return await db.delete('pack', where: 'id = ?', whereArgs: [id]);
  }

  /// 🔹 Récupérer tous les packs avec leurs cours associés
  Future<List<Pack>> getAllPacks() async {
    final db = await _dbHelper.database;
    final rows = await db.query('pack', orderBy: 'created_at DESC');
    List<Pack> packs = [];

    for (var r in rows) {
      final pack = Pack.fromMap(r);

      final courseRows = await db.rawQuery('''
        SELECT c.* FROM courses c
        INNER JOIN pack_course pc ON c.id = pc.course_id
        WHERE pc.pack_id = ?
      ''', [pack.id]);

      final courses = courseRows.map((c) => Course.fromMap(c)).toList();
      pack.courses = courses;

      packs.add(pack);
    }

    return packs;
  }

  /// 🔹 Récupérer un pack par ID (avec ses cours)
  Future<Pack?> getPackById(int id) async {
    final db = await _dbHelper.database;
    final res = await db.query('pack', where: 'id = ?', whereArgs: [id], limit: 1);
    if (res.isEmpty) return null;

    final pack = Pack.fromMap(res.first);

    final courseRows = await db.rawQuery('''
      SELECT c.* FROM courses c
      INNER JOIN pack_course pc ON c.id = pc.course_id
      WHERE pc.pack_id = ?
    ''', [id]);

    pack.courses = courseRows.map((r) => Course.fromMap(r)).toList();

    return pack;
  }

  /// 🔹 Récupérer les IDs des cours d’un pack
  Future<List<int>> getCourseIdsForPack(int packId) async {
    final db = await _dbHelper.database;
    final rows = await db.query('pack_course', where: 'pack_id = ?', whereArgs: [packId]);
    return rows.map((r) => r['course_id'] as int).toList();
  }

  /// 🔹 Récupérer les cours d’un pack
  Future<List<Course>> getCoursesForPack(int packId) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('''
      SELECT c.* FROM courses c
      INNER JOIN pack_course pc ON c.id = pc.course_id
      WHERE pc.pack_id = ?
    ''', [packId]);
    return rows.map((r) => Course.fromMap(r)).toList();
  }
}
