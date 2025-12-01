import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise.dart';
import '../repositories/exercise_repository.dart';

final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  return ExerciseRepository();
});

final allExercisesProvider = FutureProvider<List<Exercise>>((ref) async {
  final repository = ref.watch(exerciseRepositoryProvider);
  return await repository.getAllExercises();
});

final filteredExercisesProvider =
    FutureProvider.family.autoDispose<List<Exercise>, ExerciseFilter>((ref, filter) async {
  final repository = ref.watch(exerciseRepositoryProvider);
  return await repository.searchAndFilterExercises(
    query: filter.searchQuery,
    muscleGroup: filter.muscleGroup,
  );
});

class ExerciseFilter {
  final String? searchQuery;
  final MuscleGroup? muscleGroup;

  const ExerciseFilter({
    this.searchQuery,
    this.muscleGroup,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExerciseFilter &&
        other.searchQuery == searchQuery &&
        other.muscleGroup == muscleGroup;
  }

  @override
  int get hashCode => Object.hash(searchQuery, muscleGroup);
}

class ExerciseNotifier extends StateNotifier<ExerciseFilter> {
  ExerciseNotifier() : super(const ExerciseFilter());

  void setSearchQuery(String? query) {
    state = ExerciseFilter(
      searchQuery: query,
      muscleGroup: state.muscleGroup,
    );
  }

  void setMuscleGroup(MuscleGroup? muscle) {
    state = ExerciseFilter(
      searchQuery: state.searchQuery,
      muscleGroup: muscle,
    );
  }

  void clearFilters() {
    state = const ExerciseFilter();
  }
}

final exerciseFilterProvider =
    StateNotifierProvider<ExerciseNotifier, ExerciseFilter>((ref) {
  return ExerciseNotifier();
});
