import '../core/database/database_helper.dart';
import '../models/scheduled_workout.dart';

class ScheduledWorkoutRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> createScheduledWorkout(ScheduledWorkout workout) async {
    final db = await _dbHelper.database;
    return await db.insert('scheduled_workouts', workout.toMap());
  }

  Future<List<ScheduledWorkout>> getAllScheduledWorkouts() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'scheduled_workouts',
      orderBy: 'scheduled_date ASC',
    );
    return maps.map((map) => ScheduledWorkout.fromMap(map)).toList();
  }

  Future<List<ScheduledWorkout>> getScheduledWorkoutsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'scheduled_workouts',
      where: 'scheduled_date BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'scheduled_date ASC',
    );
    return maps.map((map) => ScheduledWorkout.fromMap(map)).toList();
  }

  Future<List<ScheduledWorkout>> getScheduledWorkoutsForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'scheduled_workouts',
      where: 'scheduled_date BETWEEN ? AND ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'scheduled_date ASC',
    );
    return maps.map((map) => ScheduledWorkout.fromMap(map)).toList();
  }

  Future<List<ScheduledWorkout>> getUpcomingWorkouts({int limit = 7}) async {
    final now = DateTime.now();
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'scheduled_workouts',
      where: 'scheduled_date >= ? AND completed = 0',
      whereArgs: [now.toIso8601String()],
      orderBy: 'scheduled_date ASC',
      limit: limit,
    );
    return maps.map((map) => ScheduledWorkout.fromMap(map)).toList();
  }

  Future<ScheduledWorkout?> getScheduledWorkoutById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'scheduled_workouts',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return ScheduledWorkout.fromMap(maps.first);
  }

  Future<int> updateScheduledWorkout(ScheduledWorkout workout) async {
    final db = await _dbHelper.database;
    return await db.update(
      'scheduled_workouts',
      workout.toMap(),
      where: 'id = ?',
      whereArgs: [workout.id],
    );
  }

  Future<int> markAsCompleted(int id, int sessionId) async {
    final db = await _dbHelper.database;
    return await db.update(
      'scheduled_workouts',
      {
        'completed': 1,
        'completed_session_id': sessionId,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteScheduledWorkout(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'scheduled_workouts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getScheduledWorkoutCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM scheduled_workouts');
    return result.first['count'] as int;
  }

  Future<int> getCompletedCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM scheduled_workouts WHERE completed = 1',
    );
    return result.first['count'] as int;
  }
}
