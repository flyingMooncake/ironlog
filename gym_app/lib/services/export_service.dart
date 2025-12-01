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

class ExportService {
  final WorkoutRepository _workoutRepo = WorkoutRepository();
  final SetRepository _setRepo = SetRepository();
  final ExerciseRepository _exerciseRepo = ExerciseRepository();
  final TargetRepository _targetRepo = TargetRepository();
  final UserRepository _userRepo = UserRepository();
  final WeightHistoryRepository _weightHistoryRepo = WeightHistoryRepository();

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
    final file = File(filePath);

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
}
