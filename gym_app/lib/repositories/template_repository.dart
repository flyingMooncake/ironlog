import 'package:sqflite/sqflite.dart';
import '../core/database/database_helper.dart';
import '../models/workout_template.dart';
import '../models/exercise.dart';
import 'exercise_repository.dart';

class TemplateRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ExerciseRepository _exerciseRepo = ExerciseRepository();

  // Create a new template
  Future<int> createTemplate(WorkoutTemplate template) async {
    final db = await _dbHelper.database;

    // Insert template
    final templateId = await db.insert(
      'workout_templates',
      template.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Insert template exercises
    for (final exercise in template.exercises) {
      await db.insert(
        'template_exercises',
        exercise.copyWith(templateId: templateId).toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    return templateId;
  }

  // Get all templates
  Future<List<WorkoutTemplate>> getAllTemplates() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'workout_templates',
      orderBy: 'last_used DESC, name ASC',
    );

    final templates = <WorkoutTemplate>[];
    for (final map in result) {
      final template = WorkoutTemplate.fromMap(map);
      final exercises = await getTemplateExercises(template.id!);
      templates.add(template.copyWith(exercises: exercises));
    }

    return templates;
  }

  // Get template by ID
  Future<WorkoutTemplate?> getTemplate(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'workout_templates',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isEmpty) return null;

    final template = WorkoutTemplate.fromMap(result.first);
    final exercises = await getTemplateExercises(id);
    return template.copyWith(exercises: exercises);
  }

  // Get exercises for a template
  Future<List<TemplateExercise>> getTemplateExercises(int templateId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'template_exercises',
      where: 'template_id = ?',
      whereArgs: [templateId],
      orderBy: 'order_index ASC',
    );

    return result.map((map) => TemplateExercise.fromMap(map)).toList();
  }

  // Update template
  Future<int> updateTemplate(WorkoutTemplate template) async {
    final db = await _dbHelper.database;

    // Update template
    final count = await db.update(
      'workout_templates',
      template.toMap(),
      where: 'id = ?',
      whereArgs: [template.id],
    );

    // Delete existing exercises
    await db.delete(
      'template_exercises',
      where: 'template_id = ?',
      whereArgs: [template.id],
    );

    // Insert updated exercises
    for (final exercise in template.exercises) {
      await db.insert(
        'template_exercises',
        exercise.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    return count;
  }

  // Delete template
  Future<int> deleteTemplate(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'workout_templates',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Update last used timestamp
  Future<void> markTemplateUsed(int id) async {
    final db = await _dbHelper.database;
    await db.update(
      'workout_templates',
      {'last_used': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get template exercises with full exercise details
  Future<List<Map<String, dynamic>>> getTemplateExercisesWithDetails(int templateId) async {
    final templateExercises = await getTemplateExercises(templateId);
    final result = <Map<String, dynamic>>[];

    for (final te in templateExercises) {
      final exercise = await _exerciseRepo.getExerciseById(te.exerciseId);
      if (exercise != null) {
        result.add({
          'template_exercise': te,
          'exercise': exercise,
        });
      }
    }

    return result;
  }

  // Move template to a group
  Future<void> moveTemplateToGroup(int templateId, int? groupId) async {
    final db = await _dbHelper.database;
    await db.update(
      'workout_templates',
      {'group_id': groupId},
      where: 'id = ?',
      whereArgs: [templateId],
    );
  }

  // Get templates by group
  Future<List<WorkoutTemplate>> getTemplatesByGroup(int? groupId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'workout_templates',
      where: groupId == null ? 'group_id IS NULL' : 'group_id = ?',
      whereArgs: groupId == null ? null : [groupId],
      orderBy: 'order_in_group ASC, name ASC',
    );

    final templates = <WorkoutTemplate>[];
    for (final map in result) {
      final template = WorkoutTemplate.fromMap(map);
      final exercises = await getTemplateExercises(template.id!);
      templates.add(template.copyWith(exercises: exercises));
    }

    return templates;
  }
}
