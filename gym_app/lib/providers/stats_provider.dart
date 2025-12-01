import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/set_repository.dart';
import '../repositories/workout_repository.dart';
import '../models/workout_set.dart';

// Progress data for a single exercise
class ExerciseProgressData {
  final DateTime date;
  final double? maxWeight;
  final int? maxReps;
  final double? estimated1RM;
  final double totalVolume;

  ExerciseProgressData({
    required this.date,
    this.maxWeight,
    this.maxReps,
    this.estimated1RM,
    required this.totalVolume,
  });
}

// Volume data over time
class VolumeData {
  final DateTime date;
  final double volume;
  final int workoutId;

  VolumeData({
    required this.date,
    required this.volume,
    required this.workoutId,
  });
}

// Provider to get exercise progress data (limit to last 50 workouts for performance)
final exerciseProgressProvider = FutureProvider.family.autoDispose<List<ExerciseProgressData>, int>((ref, exerciseId) async {
  final setRepo = SetRepository();
  final workoutRepo = WorkoutRepository();

  // Get all sessions that include this exercise
  final sessions = await workoutRepo.getAllWorkoutSessions();
  final progressData = <ExerciseProgressData>[];

  for (final session in sessions) {
    final sets = await setRepo.getSetsBySessionId(session.id!);
    final exerciseSets = sets.where((s) => s.exerciseId == exerciseId && !s.isWarmup).toList();

    if (exerciseSets.isEmpty) continue;

    // Find max weight and reps for this session
    double? maxWeight;
    int? maxReps;
    double? best1RM;
    double totalVolume = 0;

    for (final set in exerciseSets) {
      if (set.weight != null && set.reps != null) {
        if (maxWeight == null || set.weight! > maxWeight) {
          maxWeight = set.weight;
        }
        if (maxReps == null || set.reps! > maxReps) {
          maxReps = set.reps;
        }

        // Calculate 1RM
        final estimated1RM = set.weight! * (1 + set.reps! / 30);
        if (best1RM == null || estimated1RM > best1RM) {
          best1RM = estimated1RM;
        }

        totalVolume += set.weight! * set.reps!;
      }
    }

    progressData.add(ExerciseProgressData(
      date: session.startedAt,
      maxWeight: maxWeight,
      maxReps: maxReps,
      estimated1RM: best1RM,
      totalVolume: totalVolume,
    ));
  }

  // Sort by date
  progressData.sort((a, b) => a.date.compareTo(b.date));

  // Limit to last 50 workouts for performance
  if (progressData.length > 50) {
    return progressData.sublist(progressData.length - 50);
  }

  return progressData;
});

// Provider to get total volume over time (limit to last 60 workouts)
final volumeOverTimeProvider = FutureProvider.autoDispose<List<VolumeData>>((ref) async {
  final workoutRepo = WorkoutRepository();
  final sessions = await workoutRepo.getAllWorkoutSessions();

  final volumeData = <VolumeData>[];

  for (final session in sessions) {
    if (session.totalVolume != null && session.totalVolume! > 0) {
      volumeData.add(VolumeData(
        date: session.startedAt,
        volume: session.totalVolume!,
        workoutId: session.id!,
      ));
    }
  }

  // Sort by date
  volumeData.sort((a, b) => a.date.compareTo(b.date));

  // Limit to last 60 workouts for better performance
  if (volumeData.length > 60) {
    return volumeData.sublist(volumeData.length - 60);
  }

  return volumeData;
});

// Provider to get muscle group volume breakdown
final muscleGroupVolumeProvider = FutureProvider.family.autoDispose<Map<String, double>, StatsDateRange>((ref, dateRange) async {
  final workoutRepo = WorkoutRepository();
  final setRepo = SetRepository();

  // Get all sessions in the date range
  final sessions = await workoutRepo.getAllWorkoutSessions();
  final filteredSessions = sessions.where((s) {
    return s.startedAt.isAfter(dateRange.start.subtract(const Duration(days: 1))) &&
           s.startedAt.isBefore(dateRange.end.add(const Duration(days: 1)));
  }).toList();

  final muscleVolumes = <String, double>{};

  for (final session in filteredSessions) {
    final muscleGroupsForSession = await workoutRepo.getMuscleGroupsForSession(session.id!);

    for (final muscleGroup in muscleGroupsForSession) {
      // Get volume for this muscle group in this session
      final sets = await setRepo.getSetsBySessionId(session.id!);

      double volume = 0;
      for (final set in sets) {
        if (!set.isWarmup && set.weight != null && set.reps != null) {
          volume += set.weight! * set.reps!;
        }
      }

      muscleVolumes[muscleGroup] = (muscleVolumes[muscleGroup] ?? 0) + volume;
    }
  }

  return muscleVolumes;
});

// Helper class for date range
class StatsDateRange {
  final DateTime start;
  final DateTime end;

  StatsDateRange({required this.start, required this.end});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StatsDateRange &&
        other.start == start &&
        other.end == end;
  }

  @override
  int get hashCode => Object.hash(start, end);
}
