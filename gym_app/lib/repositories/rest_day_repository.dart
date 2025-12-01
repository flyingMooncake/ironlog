import '../core/database/database_helper.dart';
import '../models/rest_day.dart';

class RestDayRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> createRestDay(RestDay restDay) async {
    final db = await _dbHelper.database;
    return await db.insert('rest_days', restDay.toMap());
  }

  Future<List<RestDay>> getAllRestDays() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'rest_days',
      orderBy: 'rest_date DESC',
    );
    return maps.map((map) => RestDay.fromMap(map)).toList();
  }

  Future<List<RestDay>> getRestDaysByDateRange(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'rest_days',
      where: 'rest_date BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'rest_date ASC',
    );
    return maps.map((map) => RestDay.fromMap(map)).toList();
  }

  Future<RestDay?> getRestDayForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'rest_days',
      where: 'rest_date BETWEEN ? AND ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return RestDay.fromMap(maps.first);
  }

  Future<bool> isRestDay(DateTime date) async {
    final restDay = await getRestDayForDate(date);
    return restDay != null;
  }

  Future<RestDay?> getRestDayById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'rest_days',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return RestDay.fromMap(maps.first);
  }

  Future<int> updateRestDay(RestDay restDay) async {
    final db = await _dbHelper.database;
    return await db.update(
      'rest_days',
      restDay.toMap(),
      where: 'id = ?',
      whereArgs: [restDay.id],
    );
  }

  Future<int> deleteRestDay(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'rest_days',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteRestDayForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final db = await _dbHelper.database;
    return await db.delete(
      'rest_days',
      where: 'rest_date BETWEEN ? AND ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );
  }

  Future<int> getRestDayCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM rest_days');
    return result.first['count'] as int;
  }

  Future<List<RestDay>> getPlannedRestDays() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'rest_days',
      where: 'is_planned = 1',
      orderBy: 'rest_date DESC',
    );
    return maps.map((map) => RestDay.fromMap(map)).toList();
  }
}
