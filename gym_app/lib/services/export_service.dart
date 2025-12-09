import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../repositories/workout_repository.dart';
import '../repositories/set_repository.dart';
import '../repositories/exercise_repository.dart';
import '../repositories/target_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/weight_history_repository.dart';
import '../repositories/template_group_repository.dart';
import '../repositories/template_repository.dart';

class ExportService {
  final WorkoutRepository _workoutRepo = WorkoutRepository();
  final SetRepository _setRepo = SetRepository();
  final ExerciseRepository _exerciseRepo = ExerciseRepository();
  final TargetRepository _targetRepo = TargetRepository();
  final UserRepository _userRepo = UserRepository();
  final WeightHistoryRepository _weightHistoryRepo = WeightHistoryRepository();
  final TemplateGroupRepository _templateGroupRepo = TemplateGroupRepository();
  final TemplateRepository _templateRepo = TemplateRepository();

  /// Export all data to JSON format
  Future<Map<String, dynamic>> exportAllData() async {
    final workoutSessions = await _workoutRepo.getAllWorkoutSessions();
    final exercises = await _exerciseRepo.getAllExercises();
    final targets = await _targetRepo.getAllTargets();
    final userProfile = await _userRepo.getUserProfile();
    final weightHistory = await _weightHistoryRepo.getAllWeightEntries();

    // Get all sets for all sessions
    final allSets = <Map<String, dynamic>>[];
    for (final session in workoutSessions) {
      final sets = await _setRepo.getSetsBySessionId(session.id!);
      allSets.addAll(sets.map((set) => set.toMap()));
    }

    return {
      'export_date': DateTime.now().toIso8601String(),
      'version': '1.0.0',
      'user_profile': userProfile?.toMap(),
      'weight_history': weightHistory.map((entry) => entry.toMap()).toList(),
      'exercises': exercises.map((exercise) => exercise.toMap()).toList(),
      'workout_sessions': workoutSessions.map((session) => session.toMap()).toList(),
      'workout_sets': allSets,
      'exercise_targets': targets.map((target) => target.toMap()).toList(),
    };
  }

  /// Export data to JSON file and return the file path
  Future<String> exportToJsonFile() async {
    final data = await exportAllData();
    final jsonString = const JsonEncoder.withIndent('  ').convert(data);

    // Get directory for saving
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
    final fileName = 'ironlog_backup_$timestamp.json';
    final filePath = '${directory.path}/$fileName';

    // Write to file
    final file = File(filePath);
    await file.writeAsString(jsonString);

    return filePath;
  }

  /// Export and share the JSON file
  Future<void> exportAndShare() async {
    final filePath = await exportToJsonFile();

    await Share.shareXFiles(
      [XFile(filePath)],
      subject: 'IronLog Data Export',
      text: 'My IronLog workout data backup',
    );
  }

  /// Get export data size in bytes
  Future<int> getExportSize() async {
    final data = await exportAllData();
    final jsonString = jsonEncode(data);
    return jsonString.length;
  }

  /// Get export statistics
  Future<Map<String, int>> getExportStats() async {
    final workoutSessions = await _workoutRepo.getAllWorkoutSessions();
    final exercises = await _exerciseRepo.getAllExercises();
    final targets = await _targetRepo.getAllTargets();
    final weightHistory = await _weightHistoryRepo.getAllWeightEntries();

    int totalSets = 0;
    for (final session in workoutSessions) {
      final sets = await _setRepo.getSetsBySessionId(session.id!);
      totalSets += sets.length;
    }

    return {
      'workouts': workoutSessions.length,
      'exercises': exercises.length,
      'sets': totalSets,
      'targets': targets.length,
      'weight_entries': weightHistory.length,
    };
  }

  /// Export a single workout to JSON format
  Future<Map<String, dynamic>> exportSingleWorkout(int workoutId) async {
    final session = await _workoutRepo.getWorkoutSessionById(workoutId);
    if (session == null) {
      throw Exception('Workout not found');
    }

    final sets = await _setRepo.getSetsBySessionId(workoutId);

    // Get unique exercises used in this workout
    final exerciseIds = sets.map((set) => set.exerciseId).toSet();
    final exercises = <Map<String, dynamic>>[];
    for (final exerciseId in exerciseIds) {
      final exercise = await _exerciseRepo.getExerciseById(exerciseId);
      if (exercise != null) {
        exercises.add(exercise.toMap());
      }
    }

    return {
      'export_date': DateTime.now().toIso8601String(),
      'version': '1.0.0',
      'workout_session': session.toMap(),
      'workout_sets': sets.map((set) => set.toMap()).toList(),
      'exercises': exercises,
    };
  }

  /// Export a single workout to JSON file and share
  Future<void> exportAndShareSingleWorkout(int workoutId) async {
    final data = await exportSingleWorkout(workoutId);
    final jsonString = const JsonEncoder.withIndent('  ').convert(data);

    // Get directory for saving
    final directory = await getApplicationDocumentsDirectory();
    final session = await _workoutRepo.getWorkoutSessionById(workoutId);
    final workoutName = session?.name ?? 'workout';
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
    final fileName = 'ironlog_${workoutName.replaceAll(' ', '_').toLowerCase()}_$timestamp.json';
    final filePath = '${directory.path}/$fileName';

    // Write to file
    final file = File(filePath);
    await file.writeAsString(jsonString);

    await Share.shareXFiles(
      [XFile(filePath)],
      subject: 'IronLog Workout Export - $workoutName',
      text: 'My workout: $workoutName',
    );
  }

  /// Export a single template group to JSON format
  Future<Map<String, dynamic>> exportSingleGroup(int groupId) async {
    final group = await _templateGroupRepo.getGroupById(groupId);
    if (group == null) {
      throw Exception('Group not found');
    }

    final templates = await _templateRepo.getTemplatesByGroup(groupId);

    // Get all template exercises and exercises used in this group
    final allTemplateExercises = <Map<String, dynamic>>[];
    final exerciseIds = <int>{};

    for (final template in templates) {
      for (final templateExercise in template.exercises) {
        allTemplateExercises.add(templateExercise.toMap());
        exerciseIds.add(templateExercise.exerciseId);
      }
    }

    // Get full exercise details
    final exercises = <Map<String, dynamic>>[];
    for (final exerciseId in exerciseIds) {
      final exercise = await _exerciseRepo.getExerciseById(exerciseId);
      if (exercise != null) {
        exercises.add(exercise.toMap());
      }
    }

    return {
      'export_date': DateTime.now().toIso8601String(),
      'version': '1.0.0',
      'template_group': group.toMap(),
      'workout_templates': templates.map((template) => template.toMap()).toList(),
      'template_exercises': allTemplateExercises,
      'exercises': exercises,
    };
  }

  /// Export a single template group to JSON file and share
  Future<void> exportAndShareSingleGroup(int groupId) async {
    final data = await exportSingleGroup(groupId);
    final jsonString = const JsonEncoder.withIndent('  ').convert(data);

    // Get directory for saving
    final directory = await getApplicationDocumentsDirectory();
    final group = await _templateGroupRepo.getGroupById(groupId);
    final groupName = group?.name ?? 'group';
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
    final fileName = 'ironlog_${groupName.replaceAll(' ', '_').toLowerCase()}_$timestamp.json';
    final filePath = '${directory.path}/$fileName';

    // Write to file
    final file = File(filePath);
    await file.writeAsString(jsonString);

    await Share.shareXFiles(
      [XFile(filePath)],
      subject: 'IronLog Group Export - $groupName',
      text: 'My template group: $groupName',
    );
  }
}
