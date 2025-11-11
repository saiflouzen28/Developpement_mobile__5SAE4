import '../database/database_helper.dart';
import '../models/pack.dart';

class PaymentRepository {
  final DatabaseHelper dbHelper = DatabaseHelper.instance;

  Future<void> recordPaymentAndGrant(int userId, Pack pack) async {
    final db = await dbHelper.database;
    final now = DateTime.now();
    final end = now.add(Duration(days: pack.durationDays));

    await db.insert('payments', {
      'user_id': userId,
      'pack_id': pack.id,
      'amount': pack.price,
      'date': now.millisecondsSinceEpoch,
      'status': 'paid',
    });

    await db.insert('user_packs', {
      'user_id': userId,
      'pack_id': pack.id,
      'start_date': now.millisecondsSinceEpoch,
      'end_date': end.millisecondsSinceEpoch,
    });
  }

  Future<List<Map<String, dynamic>>> getUserPacksRaw(int userId) async {
    final db = await dbHelper.database;
    return await db.query('user_packs', where: 'user_id = ?', whereArgs: [userId]);
  }
}
