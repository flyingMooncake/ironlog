import 'package:sqflite/sqflite.dart';
import '../core/database/database_helper.dart';
import '../models/exercise.dart';

class ExerciseRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<Exercise>> getAllExercises() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'exercises',
      orderBy: 'name ASC',
    );
    return result.map((map) => Exercise.fromMap(map)).toList();
  }

  Future<Exercise?> getExerciseById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'exercises',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return Exercise.fromMap(result.first);
  }

  Future<List<Exercise>> searchExercises(String query) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'exercises',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'name ASC',
    );
    return result.map((map) => Exercise.fromMap(map)).toList();
  }

  Future<List<Exercise>> getExercisesByMuscleGroup(MuscleGroup muscle) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'exercises',
      where: 'primary_muscle = ?',
      whereArgs: [muscle.name],
      orderBy: 'name ASC',
    );
    return result.map((map) => Exercise.fromMap(map)).toList();
  }

  Future<List<Exercise>> searchAndFilterExercises({
    String? query,
    MuscleGroup? muscleGroup,
  }) async {
    final db = await _dbHelper.database;

    String? whereClause;
    List<dynamic>? whereArgs;

    if (query != null && query.isNotEmpty && muscleGroup != null) {
      whereClause = 'name LIKE ? AND primary_muscle = ?';
      whereArgs = ['%$query%', muscleGroup.name];
    } else if (query != null && query.isNotEmpty) {
      whereClause = 'name LIKE ?';
      whereArgs = ['%$query%'];
    } else if (muscleGroup != null) {
      whereClause = 'primary_muscle = ?';
      whereArgs = [muscleGroup.name];
    }

    final result = await db.query(
      'exercises',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'name ASC',
    );
    return result.map((map) => Exercise.fromMap(map)).toList();
  }

  Future<int> createExercise(Exercise exercise) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'exercises',
      exercise.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateExercise(Exercise exercise) async {
    final db = await _dbHelper.database;
    return await db.update(
      'exercises',
      exercise.toMap(),
      where: 'id = ?',
      whereArgs: [exercise.id],
    );
  }

  Future<int> deleteExercise(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'exercises',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Exercise>> getCustomExercises() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'exercises',
      where: 'is_custom = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
    return result.map((map) => Exercise.fromMap(map)).toList();
  }
}
