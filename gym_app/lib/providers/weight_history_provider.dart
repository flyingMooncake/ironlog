import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/weight_entry.dart';
import '../repositories/weight_history_repository.dart';

// Provider for weight history repository
final weightHistoryRepositoryProvider = Provider<WeightHistoryRepository>((ref) {
  return WeightHistoryRepository();
});

// Provider for all weight entries
final allWeightEntriesProvider = FutureProvider.autoDispose<List<WeightEntry>>((ref) async {
  final repo = ref.watch(weightHistoryRepositoryProvider);
  return await repo.getAllWeightEntries();
});

// Provider for latest weight entry
final latestWeightEntryProvider = FutureProvider.autoDispose<WeightEntry?>((ref) async {
  final repo = ref.watch(weightHistoryRepositoryProvider);
  return await repo.getLatestWeightEntry();
});

// Provider for weight change over a period
final weightChangeProvider = FutureProvider.family.autoDispose<Map<String, double>, int>((ref, days) async {
  final repo = ref.watch(weightHistoryRepositoryProvider);
  return await repo.getWeightChange(days);
});
