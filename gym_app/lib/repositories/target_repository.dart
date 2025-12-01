import 'package:sqflite/sqflite.dart';
import '../core/database/database_helper.dart';
import '../models/exercise_target.dart';

class TargetRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Create a new target
  Future<int> createTarget(ExerciseTarget target) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'exercise_targets',
      target.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all targets for an exercise
  Future<List<ExerciseTarget>> getTargetsForExercise(int exerciseId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'exercise_targets',
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
      orderBy: 'created_at DESC',
    );
    return result.map((map) => ExerciseTarget.fromMap(map)).toList();
  }

  // Get all active (unachieved) targets
  Future<List<ExerciseTarget>> getActiveTargets() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'exercise_targets',
      where: 'achieved_at IS NULL',
      orderBy: 'deadline ASC',
    );
    return result.map((map) => ExerciseTarget.fromMap(map)).toList();
  }

  // Get all targets
  Future<List<ExerciseTarget>> getAllTargets() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'exercise_targets',
      orderBy: 'created_at DESC',
    );
    return result.map((map) => ExerciseTarget.fromMap(map)).toList();
  }

  // Update target
  Future<int> updateTarget(ExerciseTarget target) async {
    final db = await _dbHelper.database;
    return await db.update(
      'exercise_targets',
      target.toMap(),
      where: 'id = ?',
      whereArgs: [target.id],
    );
  }

  // Delete target
  Future<int> deleteTarget(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'exercise_targets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Mark target as achieved
  Future<int> markTargetAsAchieved(int id) async {
    final db = await _dbHelper.database;
    return await db.update(
      'exercise_targets',
      {'achieved_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Update target progress based on latest workout data
  Future<void> updateTargetProgress(int exerciseId) async {
    final db = await _dbHelper.database;

    // Get all targets for this exercise
    final targets = await getTargetsForExercise(exerciseId);

    for (final target in targets) {
      if (target.isAchieved) continue;

      double currentValue = 0;

      switch (target.targetType) {
        case TargetType.weight:
          // Get max weight ever lifted
          final weightResult = await db.rawQuery('''
            SELECT MAX(weight) as max_weight
            FROM workout_sets
            WHERE exercise_id = ? AND is_warmup = 0
          ''', [exerciseId]);
          currentValue = (weightResult.first['max_weight'] as num?)?.toDouble() ?? 0;
          break;

        case TargetType.reps:
          // Get max reps ever done
          final repsResult = await db.rawQuery('''
            SELECT MAX(reps) as max_reps
            FROM workout_sets
            WHERE exercise_id = ? AND is_warmup = 0
          ''', [exerciseId]);
          currentValue = (repsResult.first['max_reps'] as num?)?.toDouble() ?? 0;
          break;

        case TargetType.oneRM:
          // Get best estimated 1RM
          final oneRMResult = await db.rawQuery('''
            SELECT MAX(weight * (1 + reps / 30.0)) as best_1rm
            FROM workout_sets
            WHERE exercise_id = ? AND is_warmup = 0 AND weight IS NOT NULL AND reps IS NOT NULL
          ''', [exerciseId]);
          currentValue = (oneRMResult.first['best_1rm'] as num?)?.toDouble() ?? 0;
          break;

        case TargetType.volume:
          // Get max volume in a single workout
          final volumeResult = await db.rawQuery('''
            SELECT MAX(session_volume) as max_volume
            FROM (
              SELECT session_id, SUM(weight * reps) as session_volume
              FROM workout_sets
              WHERE exercise_id = ? AND is_warmup = 0
              GROUP BY session_id
            )
          ''', [exerciseId]);
          currentValue = (volumeResult.first['max_volume'] as num?)?.toDouble() ?? 0;
          break;

        case TargetType.frequency:
          // Count workouts in the last 7 days
          final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
          final frequencyResult = await db.rawQuery('''
            SELECT COUNT(DISTINCT s.session_id) as workout_count
            FROM workout_sets s
            JOIN workout_sessions ws ON s.session_id = ws.id
            WHERE s.exercise_id = ? AND ws.started_at >= ?
          ''', [exerciseId, sevenDaysAgo.toIso8601String()]);
          currentValue = (frequencyResult.first['workout_count'] as num?)?.toDouble() ?? 0;
          break;
      }

      // Update the target's current value
      final updatedTarget = target.copyWith(currentValue: currentValue);
      await updateTarget(updatedTarget);

      // Mark as achieved if target reached
      if (currentValue >= target.targetValue && target.achievedAt == null) {
        await markTargetAsAchieved(target.id!);
      }
    }
  }
}
