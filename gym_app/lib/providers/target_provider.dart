import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise_target.dart';
import '../repositories/target_repository.dart';

// Provider for target repository
final targetRepositoryProvider = Provider<TargetRepository>((ref) {
  return TargetRepository();
});

// Provider for targets for a specific exercise
final exerciseTargetsProvider = FutureProvider.family.autoDispose<List<ExerciseTarget>, int>((ref, exerciseId) async {
  final repo = ref.watch(targetRepositoryProvider);
  return await repo.getTargetsForExercise(exerciseId);
});

// Provider for all active targets
final activeTargetsProvider = FutureProvider.autoDispose<List<ExerciseTarget>>((ref) async {
  final repo = ref.watch(targetRepositoryProvider);
  return await repo.getActiveTargets();
});

// Provider for all targets
final allTargetsProvider = FutureProvider.autoDispose<List<ExerciseTarget>>((ref) async {
  final repo = ref.watch(targetRepositoryProvider);
  return await repo.getAllTargets();
});
