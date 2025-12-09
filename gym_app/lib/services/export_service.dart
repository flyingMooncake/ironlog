import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/workout_session.dart';
import '../models/workout_set.dart';
import '../models/exercise.dart';
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

  /// Import a single workout from JSON data
  Future<int> importSingleWorkout(Map<String, dynamic> data) async {
    // Validate data structure
    if (!data.containsKey('workout_session') || !data.containsKey('workout_sets')) {
      throw Exception('Invalid workout export format');
    }

    final sessionData = data['workout_session'] as Map<String, dynamic>;
    final setsData = data['workout_sets'] as List<dynamic>;
    final exercisesData = data['exercises'] as List<dynamic>?;

    // Import exercises if they don't exist
    if (exercisesData != null) {
      for (final exerciseData in exercisesData) {
        final exerciseMap = exerciseData as Map<String, dynamic>;
        final exerciseId = exerciseMap['id'] as int?;

        if (exerciseId != null) {
          final existing = await _exerciseRepo.getExerciseById(exerciseId);
          if (existing == null) {
            // Exercise doesn't exist, create it
            final exercise = Exercise.fromMap(exerciseMap);
            await _exerciseRepo.createExercise(exercise);
          }
        }
      }
    }

    // Create workout session (without id to get a new one)
    final sessionMap = Map<String, dynamic>.from(sessionData);
    sessionMap.remove('id'); // Remove old ID to generate new one

    final session = WorkoutSession.fromMap(sessionMap);
    final newSessionId = await _workoutRepo.createWorkoutSession(session);

    // Create workout sets with new session ID
    for (final setData in setsData) {
      final setMap = Map<String, dynamic>.from(setData as Map<String, dynamic>);
      setMap.remove('id'); // Remove old ID
      setMap['session_id'] = newSessionId; // Set new session ID

      final set = WorkoutSet.fromMap(setMap);
      await _setRepo.createSet(set);
    }

    return newSessionId;
  }
}
