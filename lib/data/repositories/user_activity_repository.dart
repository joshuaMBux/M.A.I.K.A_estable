import 'package:sqflite/sqflite.dart';

import '../../core/database/database_helper.dart';

class UserActivityRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> getCurrentStreak(int userId) async {
    final Database db = await _dbHelper.database;

    final rows = await db.query(
      'racha_usuario',
      where: 'id_usuario = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return 0;
    }

    final value = rows.first['racha_actual'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }
}

