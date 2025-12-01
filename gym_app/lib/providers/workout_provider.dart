import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout_session.dart';
import '../repositories/workout_repository.dart';

// Provider for workout repository
final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return WorkoutRepository();
});

// Provider for all workout sessions (cached for calendar)
final allWorkoutSessionsProvider = FutureProvider.autoDispose<List<WorkoutSession>>((ref) async {
  final repo = ref.watch(workoutRepositoryProvider);
  return await repo.getAllWorkoutSessions();
});

// Provider for workout sessions by date range
final workoutSessionsByDateRangeProvider = FutureProvider.family.autoDispose<List<WorkoutSession>, DateRange>((ref, dateRange) async {
  final repo = ref.watch(workoutRepositoryProvider);
  return await repo.getWorkoutSessionsByDateRange(
    startDate: dateRange.startDate,
    endDate: dateRange.endDate,
  );
});

// Provider for workout sessions grouped by date (for calendar)
final workoutSessionsGroupedProvider = FutureProvider.family.autoDispose<Map<DateTime, List<WorkoutSession>>, DateRange>((ref, dateRange) async {
  final repo = ref.watch(workoutRepositoryProvider);
  return await repo.getWorkoutSessionsGroupedByDate(
    startDate: dateRange.startDate,
    endDate: dateRange.endDate,
  );
});

// Provider for workout sessions on a specific date
final workoutSessionsByDateProvider = FutureProvider.family.autoDispose<List<WorkoutSession>, DateTime>((ref, date) async {
  final repo = ref.watch(workoutRepositoryProvider);
  return await repo.getWorkoutSessionsByDate(date);
});

// Provider for workout details
final workoutDetailsProvider = FutureProvider.family.autoDispose<WorkoutDetails?, int>((ref, sessionId) async {
  final repo = ref.watch(workoutRepositoryProvider);
  return await repo.getWorkoutDetails(sessionId);
});

// Provider for muscle groups in a session
final muscleGroupsForSessionProvider = FutureProvider.family.autoDispose<List<String>, int>((ref, sessionId) async {
  final repo = ref.watch(workoutRepositoryProvider);
  return await repo.getMuscleGroupsForSession(sessionId);
});

// Helper class for date range queries
class DateRange {
  final DateTime startDate;
  final DateTime endDate;

  DateRange({
    required this.startDate,
    required this.endDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRange &&
          runtimeType == other.runtimeType &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode => startDate.hashCode ^ endDate.hashCode;
}
