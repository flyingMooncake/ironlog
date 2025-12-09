import 'package:sqflite/sqflite.dart';
import '../core/database/database_helper.dart';
import '../models/workout_session.dart';
import '../models/workout_set.dart';
import '../models/exercise.dart';

class WorkoutRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Create a new workout session
  Future<int> createWorkoutSession(WorkoutSession session) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'workout_sessions',
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Update an existing workout session
  Future<int> updateWorkoutSession(WorkoutSession session) async {
    final db = await _dbHelper.database;
    return await db.update(
      'workout_sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  // Get a workout session by ID
  Future<WorkoutSession?> getWorkoutSessionById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'workout_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return WorkoutSession.fromMap(result.first);
  }

  // Get all workout sessions
  Future<List<WorkoutSession>> getAllWorkoutSessions() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'workout_sessions',
      orderBy: 'started_at DESC',
    );
    return result.map((map) => WorkoutSession.fromMap(map)).toList();
  }

  // Get workout sessions within a date range
  Future<List<WorkoutSession>> getWorkoutSessionsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'workout_sessions',
      where: 'started_at BETWEEN ? AND ?',
      whereArgs: [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'started_at DESC',
    );
    return result.map((map) => WorkoutSession.fromMap(map)).toList();
  }

  // Alias for getWorkoutSessionsByDateRange for convenience
  Future<List<WorkoutSession>> getWorkoutSessionsInRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return getWorkoutSessionsByDateRange(
      startDate: startDate,
      endDate: endDate,
    );
  }

  // Get workout sessions for a specific date
  Future<List<WorkoutSession>> getWorkoutSessionsByDate(DateTime date) async {
    final db = await _dbHelper.database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final result = await db.query(
      'workout_sessions',
      where: 'started_at BETWEEN ? AND ?',
      whereArgs: [
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String(),
      ],
      orderBy: 'started_at DESC',
    );
    return result.map((map) => WorkoutSession.fromMap(map)).toList();
  }

  // Get workout sessions grouped by date (for calendar)
  Future<Map<DateTime, List<WorkoutSession>>> getWorkoutSessionsGroupedByDate({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final sessions = await getWorkoutSessionsByDateRange(
      startDate: startDate,
      endDate: endDate,
    );

    final Map<DateTime, List<WorkoutSession>> grouped = {};

    for (final session in sessions) {
      final dateKey = DateTime(
        session.startedAt.year,
        session.startedAt.month,
        session.startedAt.day,
      );

      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(session);
    }

    return grouped;
  }

  // Delete a workout session (cascade deletes sets)
  Future<int> deleteWorkoutSession(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'workout_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get workout details with exercises and sets
  Future<WorkoutDetails?> getWorkoutDetails(int sessionId) async {
    final session = await getWorkoutSessionById(sessionId);
    if (session == null) return null;

    final db = await _dbHelper.database;

    // Get all sets for this session with exercise info
    final result = await db.rawQuery('''
      SELECT
        s.*,
        e.id as exercise_id,
        e.name as exercise_name,
        e.primary_muscle,
        e.secondary_muscles,
        e.tracking_type,
        e.equipment,
        e.is_custom,
        e.notes as exercise_notes
      FROM workout_sets s
      JOIN exercises e ON s.exercise_id = e.id
      WHERE s.session_id = ?
      ORDER BY s.id ASC
    ''', [sessionId]);

    // Group sets by exercise
    final Map<int, ExerciseWithSets> exercisesMap = {};

    for (final row in result) {
      final exerciseId = row['exercise_id'] as int;

      if (!exercisesMap.containsKey(exerciseId)) {
        final exercise = Exercise.fromMap({
          'id': row['exercise_id'],
          'name': row['exercise_name'],
          'primary_muscle': row['primary_muscle'],
          'secondary_muscles': row['secondary_muscles'],
          'tracking_type': row['tracking_type'],
          'equipment': row['equipment'],
          'is_custom': row['is_custom'],
          'notes': row['exercise_notes'],
          'created_at': DateTime.now().toIso8601String(),
        });

        exercisesMap[exerciseId] = ExerciseWithSets(
          exercise: exercise,
          sets: [],
        );
      }

      final set = WorkoutSet.fromMap({
        'id': row['id'],
        'session_id': row['session_id'],
        'exercise_id': row['exercise_id'],
        'set_order': row['set_order'],
        'weight': row['weight'],
        'reps': row['reps'],
        'duration_seconds': row['duration_seconds'],
        'rpe': row['rpe'],
        'is_warmup': row['is_warmup'],
        'superset_id': row['superset_id'],
        'notes': row['notes'],
        'completed_at': row['completed_at'],
      });

      exercisesMap[exerciseId]!.sets.add(set);
    }

    return WorkoutDetails(
      session: session,
      exercises: exercisesMap.values.toList(),
    );
  }

  // Calculate total volume for a session
  Future<double> calculateSessionVolume(int sessionId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT SUM(weight * reps) as total_volume
      FROM workout_sets
      WHERE session_id = ? AND is_warmup = 0
    ''', [sessionId]);

    return (result.first['total_volume'] as num?)?.toDouble() ?? 0.0;
  }

  // Get muscle groups trained in a session
  Future<List<String>> getMuscleGroupsForSession(int sessionId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT DISTINCT e.primary_muscle
      FROM workout_sets s
      JOIN exercises e ON s.exercise_id = e.id
      WHERE s.session_id = ?
      ORDER BY e.primary_muscle
    ''', [sessionId]);

    return result.map((row) => row['primary_muscle'] as String).toList();
  }

  // Get all workout sessions for a specific template
  Future<List<WorkoutSession>> getWorkoutSessionsByTemplateId(int templateId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'workout_sessions',
      where: 'template_id = ?',
      whereArgs: [templateId],
      orderBy: 'started_at DESC',
    );
    return result.map((map) => WorkoutSession.fromMap(map)).toList();
  }
}

// Helper class to return workout with exercises and sets
class WorkoutDetails {
  final WorkoutSession session;
  final List<ExerciseWithSets> exercises;

  WorkoutDetails({
    required this.session,
    required this.exercises,
  });
}

class ExerciseWithSets {
  final Exercise exercise;
  final List<WorkoutSet> sets;

  ExerciseWithSets({
    required this.exercise,
    required this.sets,
  });
}
