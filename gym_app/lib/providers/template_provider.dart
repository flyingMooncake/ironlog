import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout_template.dart';
import '../repositories/template_repository.dart';

// Provider for template repository
final templateRepositoryProvider = Provider<TemplateRepository>((ref) {
  return TemplateRepository();
});

// Provider for all templates (cached)
final allTemplatesProvider = FutureProvider<List<WorkoutTemplate>>((ref) async {
  final repo = ref.watch(templateRepositoryProvider);
  return await repo.getAllTemplates();
});

// Provider for a specific template
final templateProvider = FutureProvider.family.autoDispose<WorkoutTemplate?, int>((ref, id) async {
  final repo = ref.watch(templateRepositoryProvider);
  return await repo.getTemplate(id);
});
