import 'package:sqflite/sqflite.dart';

class PackStats {
  final int id;
  final String titre;
  final int totalAchats;
  final double revenus;

  PackStats({
    required this.id,
    required this.titre,
    required this.totalAchats,
    required this.revenus,
  });
}

class StatisticsService {
  final Database db;
  StatisticsService(this.db);

  // Stats : total achats et revenus par pack, filtrage période
  Future<List<PackStats>> getStats({DateTime? start, DateTime? end}) async {
    String whereClause = '';
    List<dynamic> args = [];
    if (start != null && end != null) {
      whereClause = 'WHERE start_date BETWEEN ? AND ?';
      args = [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch];
    }

    final result = await db.rawQuery('''
      SELECT p.id, p.title AS titre, 
             COUNT(up.pack_id) AS total_achats, 
             SUM(p.price) AS revenus
      FROM user_packs up
      INNER JOIN pack p ON up.pack_id = p.id
      $whereClause
      GROUP BY up.pack_id
    ''', args);

    return result.map((row) => PackStats(
      id: row['id'] as int,
      titre: row['titre'] as String,
      totalAchats: (row['total_achats'] as num).toInt(),
      revenus: (row['revenus'] as num?)?.toDouble() ?? 0.0,
    )).toList();
  }

  // Liste utilisateurs par pack
  Future<List<Map<String, dynamic>>> getUsersByPack(int packId) async {
    final result = await db.rawQuery('''
      SELECT u.nom, u.email, up.start_date
      FROM user_packs up
      INNER JOIN users u ON up.user_id = u.id
      WHERE up.pack_id = ?
      ORDER BY up.start_date DESC
    ''', [packId]);

    return result;
  }
}
