import 'package:sqflite/sqflite.dart';
import '../core/database/database_helper.dart';
import '../models/workout_set.dart';

class SetRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Create a new workout set
  Future<int> createSet(WorkoutSet set) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'workout_sets',
      set.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Create multiple sets at once (batch insert)
  Future<void> createSets(List<WorkoutSet> sets) async {
    final db = await _dbHelper.database;
    final batch = db.batch();

    for (final set in sets) {
      batch.insert(
        'workout_sets',
        set.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  // Update an existing set
  Future<int> updateSet(WorkoutSet set) async {
    final db = await _dbHelper.database;
    return await db.update(
      'workout_sets',
      set.toMap(),
      where: 'id = ?',
      whereArgs: [set.id],
    );
  }

  // Get a set by ID
  Future<WorkoutSet?> getSetById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'workout_sets',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return WorkoutSet.fromMap(result.first);
  }

  // Get all sets for a workout session
  Future<List<WorkoutSet>> getSetsBySessionId(int sessionId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'workout_sets',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'id ASC',
    );
    return result.map((map) => WorkoutSet.fromMap(map)).toList();
  }

  // Get all sets for a specific exercise in a session
  Future<List<WorkoutSet>> getSetsBySessionAndExercise({
    required int sessionId,
    required int exerciseId,
  }) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'workout_sets',
      where: 'session_id = ? AND exercise_id = ?',
      whereArgs: [sessionId, exerciseId],
      orderBy: 'set_order ASC',
    );
    return result.map((map) => WorkoutSet.fromMap(map)).toList();
  }

  // Get last workout sets for an exercise (for showing previous performance)
  Future<List<WorkoutSet>> getLastWorkoutSetsForExercise(int exerciseId) async {
    final db = await _dbHelper.database;

    // First, find the most recent session that included this exercise
    final sessionResult = await db.rawQuery('''
      SELECT DISTINCT s.session_id, ws.started_at
      FROM workout_sets s
      JOIN workout_sessions ws ON s.session_id = ws.id
      WHERE s.exercise_id = ?
      ORDER BY ws.started_at DESC
      LIMIT 1
    ''', [exerciseId]);

    if (sessionResult.isEmpty) return [];

    final lastSessionId = sessionResult.first['session_id'] as int;

    // Get all sets from that session for this exercise
    return await getSetsBySessionAndExercise(
      sessionId: lastSessionId,
      exerciseId: exerciseId,
    );
  }

  // Get the most recent non-warmup set for an exercise
  Future<WorkoutSet?> getLastSetForExercise(int exerciseId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'workout_sets',
      where: 'exercise_id = ? AND is_warmup = 0 AND weight IS NOT NULL AND reps IS NOT NULL',
      whereArgs: [exerciseId],
      orderBy: 'completed_at DESC',
      limit: 1,
    );

    if (result.isEmpty) return null;
    return WorkoutSet.fromMap(result.first);
  }

  // Get personal record for an exercise (max weight × reps)
  Future<WorkoutSet?> getPersonalRecordForExercise(int exerciseId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'workout_sets',
      where: 'exercise_id = ? AND is_warmup = 0',
      whereArgs: [exerciseId],
      orderBy: '(weight * reps) DESC',
      limit: 1,
    );

    if (result.isEmpty) return null;
    return WorkoutSet.fromMap(result.first);
  }

  // Delete a set
  Future<int> deleteSet(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'workout_sets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete all sets for a session (called when deleting a workout)
  Future<int> deleteSetsBySessionId(int sessionId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'workout_sets',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }

  // Get total volume for an exercise in a session
  Future<double> calculateExerciseVolume({
    required int sessionId,
    required int exerciseId,
  }) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT SUM(weight * reps) as total_volume
      FROM workout_sets
      WHERE session_id = ? AND exercise_id = ? AND is_warmup = 0
    ''', [sessionId, exerciseId]);

    return (result.first['total_volume'] as num?)?.toDouble() ?? 0.0;
  }

  // Check if a set is a personal record for an exercise
  Future<bool> isPR(int exerciseId, double weight, int reps) async {
    final db = await _dbHelper.database;

    // Calculate 1RM using Epley formula: 1RM = weight × (1 + reps/30)
    final current1RM = weight * (1 + reps / 30);

    // Get the best previous set for this exercise
    final result = await db.rawQuery('''
      SELECT weight, reps
      FROM workout_sets
      WHERE exercise_id = ? AND is_warmup = 0 AND weight IS NOT NULL AND reps IS NOT NULL
      ORDER BY (weight * (1 + reps / 30.0)) DESC
      LIMIT 1
    ''', [exerciseId]);

    if (result.isEmpty) return true; // First time doing this exercise

    final bestWeight = result.first['weight'] as double;
    final bestReps = result.first['reps'] as int;
    final best1RM = bestWeight * (1 + bestReps / 30);

    return current1RM > best1RM;
  }

  // Calculate 1RM for an exercise (using best set)
  Future<double?> calculate1RM(int exerciseId) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery('''
      SELECT weight, reps
      FROM workout_sets
      WHERE exercise_id = ? AND is_warmup = 0 AND weight IS NOT NULL AND reps IS NOT NULL
      ORDER BY (weight * (1 + reps / 30.0)) DESC
      LIMIT 1
    ''', [exerciseId]);

    if (result.isEmpty) return null;

    final weight = result.first['weight'] as double;
    final reps = result.first['reps'] as int;

    // Epley formula: 1RM = weight × (1 + reps/30)
    return weight * (1 + reps / 30);
  }

  // Get 1RM progression over time for an exercise
  Future<List<Map<String, dynamic>>> get1RMProgression(int exerciseId, {int limit = 10}) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery('''
      SELECT
        s.completed_at,
        s.weight,
        s.reps,
        (s.weight * (1 + s.reps / 30.0)) as estimated_1rm
      FROM workout_sets s
      WHERE s.exercise_id = ? AND s.is_warmup = 0 AND s.weight IS NOT NULL AND s.reps IS NOT NULL
      ORDER BY s.completed_at DESC
      LIMIT ?
    ''', [exerciseId, limit]);

    return result.map((row) => {
      'date': DateTime.parse(row['completed_at'] as String),
      'weight': row['weight'] as double,
      'reps': row['reps'] as int,
      'estimated_1rm': row['estimated_1rm'] as double,
    }).toList();
  }

  // Get all sets within a date range
  Future<List<WorkoutSet>> getSetsInDateRange(DateTime startDate, DateTime endDate) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'workout_sets',
      where: 'completed_at BETWEEN ? AND ?',
      whereArgs: [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'completed_at ASC',
    );
    return result.map((map) => WorkoutSet.fromMap(map)).toList();
  }
}
