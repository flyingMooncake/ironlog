import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../models/workout_template.dart';
import '../../models/exercise.dart';
import '../../providers/exercise_provider.dart';
import '../../providers/template_provider.dart';
import '../../services/haptic_service.dart';

class TemplateEditorScreen extends ConsumerStatefulWidget {
  final WorkoutTemplate template;

  const TemplateEditorScreen({
    super.key,
    required this.template,
  });

  @override
  ConsumerState<TemplateEditorScreen> createState() => _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends ConsumerState<TemplateEditorScreen> {
  late List<TemplateExercise> _exercises;
  late Map<int, String> _exerciseNames; // exerciseId -> name
  late TextEditingController _nameController;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _exercises = List.from(widget.template.exercises);
    _exerciseNames = {};
    _nameController = TextEditingController(text: widget.template.name);
    _loadExerciseNames();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadExerciseNames() async {
    final exerciseRepo = ref.read(exerciseRepositoryProvider);
    for (final te in _exercises) {
      final exercise = await exerciseRepo.getExerciseById(te.exerciseId);
      if (exercise != null) {
        _exerciseNames[te.exerciseId] = exercise.name;
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _addExercise() async {
    final selectedExercise = await showDialog<Exercise>(
      context: context,
      builder: (context) => const _ExercisePickerDialog(),
    );

    if (selectedExercise != null) {
      setState(() {
        _exercises.add(TemplateExercise(
          templateId: widget.template.id!,
          exerciseId: selectedExercise.id!,
          orderIndex: _exercises.length,
          sets: 0,
          targetReps: 0,
        ));
        _exerciseNames[selectedExercise.id!] = selectedExercise.name;
        _hasChanges = true;
      });
      HapticService.instance.light();
    }
  }

  Future<void> _saveChanges() async {
    // Validate template name
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Template name cannot be empty'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final updatedTemplate = widget.template.copyWith(
      name: _nameController.text.trim(),
      exercises: _exercises,
    );

    final repo = ref.read(templateRepositoryProvider);
    await repo.updateTemplate(updatedTemplate);
    ref.invalidate(allTemplatesProvider);

    if (mounted) {
      HapticService.instance.success();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Template saved'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_hasChanges) {
          final shouldDiscard = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text(
                'Discard Changes?',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              content: const Text(
                'You have unsaved changes. Do you want to discard them?',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Discard', style: TextStyle(color: AppColors.error)),
                ),
              ],
            ),
          );
          return shouldDiscard ?? false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Edit ${widget.template.name}'),
          elevation: 0,
          actions: [
            if (_hasChanges)
              TextButton.icon(
                onPressed: _saveChanges,
                icon: const Icon(Icons.check, color: AppColors.success),
                label: const Text(
                  'Save',
                  style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            // Template name editor
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.surface,
              child: TextField(
                controller: _nameController,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  labelText: 'Template Name',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  if (!mounted) return;
                  setState(() {
                    _hasChanges = true;
                  });
                },
              ),
            ),
            // Exercise list
            Expanded(
              child: _exercises.isEmpty
                  ? _buildEmptyState()
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _exercises.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex--;
                          final item = _exercises.removeAt(oldIndex);
                          _exercises.insert(newIndex, item);
                          // Update order indices
                          for (int i = 0; i < _exercises.length; i++) {
                            _exercises[i] = _exercises[i].copyWith(orderIndex: i);
                          }
                          _hasChanges = true;
                        });
                        HapticService.instance.light();
                      },
                      itemBuilder: (context, index) {
                        final exercise = _exercises[index];
                        return _buildExerciseCard(exercise, index);
                      },
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addExercise,
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add),
          label: const Text('Add Exercise'),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          const Text(
            'No exercises yet',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the button below to add exercises',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(TemplateExercise exercise, int index) {
    return Container(
      key: ValueKey(exercise.exerciseId),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.drag_handle,
              color: AppColors.textMuted,
            ),
            title: Text(
              _exerciseNames[exercise.exerciseId] ?? 'Unknown Exercise',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: IconButton(
              onPressed: () {
                setState(() {
                  _exercises.removeAt(index);
                  _hasChanges = true;
                });
                HapticService.instance.light();
              },
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildNumberInput(
                    label: 'Sets',
                    value: exercise.sets,
                    onChanged: (value) {
                      setState(() {
                        _exercises[index] = exercise.copyWith(sets: value);
                        _hasChanges = true;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNumberInput(
                    label: 'Target Reps',
                    value: exercise.targetReps,
                    onChanged: (value) {
                      setState(() {
                        _exercises[index] = exercise.copyWith(targetReps: value);
                        _hasChanges = true;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNumberInput(
                    label: 'Weight (kg)',
                    value: exercise.targetWeight?.toInt(),
                    onChanged: (value) {
                      setState(() {
                        _exercises[index] = exercise.copyWith(
                          targetWeight: value?.toDouble(),
                        );
                        _hasChanges = true;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberInput({
    required String label,
    required int? value,
    required Function(int?) onChanged,
  }) {
    return _NumberInputField(
      label: label,
      value: value,
      onChanged: onChanged,
    );
  }
}

class _ExercisePickerDialog extends ConsumerStatefulWidget {
  const _ExercisePickerDialog();

  @override
  ConsumerState<_ExercisePickerDialog> createState() => _ExercisePickerDialogState();
}

class _ExercisePickerDialogState extends ConsumerState<_ExercisePickerDialog> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(exerciseFilterProvider);
    final exercisesAsync = ref.watch(filteredExercisesProvider(filter));

    return Dialog(
      backgroundColor: AppColors.surface,
      child: Container(
        width: 600,
        height: 700,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Select Exercise',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                filled: true,
                fillColor: AppColors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                if (!mounted) return;
                ref
                    .read(exerciseFilterProvider.notifier)
                    .setSearchQuery(value.isEmpty ? null : value);
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: exercisesAsync.when(
                data: (exercises) => ListView.builder(
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = exercises[index];
                    return ListTile(
                      title: Text(
                        exercise.name,
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                      subtitle: Text(
                        exercise.primaryMuscle.displayName,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      onTap: () => Navigator.pop(context, exercise),
                    );
                  },
                ),
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (error, stack) => Center(
                  child: Text(
                    'Error loading exercises',
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberInputField extends StatefulWidget {
  final String label;
  final int? value;
  final Function(int?) onChanged;

  const _NumberInputField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_NumberInputField> createState() => _NumberInputFieldState();
}

class _NumberInputFieldState extends State<_NumberInputField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controller = TextEditingController(text: _formatValue(widget.value));
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!mounted) return;
    if (!_focusNode.hasFocus) {
      if (_controller.text.isEmpty) {
        setState(() {
          _controller.text = '0';
        });
        widget.onChanged(0);
      }
    }
  }

  @override
  void didUpdateWidget(_NumberInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controller if value changed externally
    if (widget.value != oldWidget.value && !_focusNode.hasFocus) {
      _controller.text = _formatValue(widget.value);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _formatValue(int? value) {
    if (value == null || value == 0) return '0';
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceElevated,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            isDense: true,
          ),
          onChanged: (text) {
            if (!mounted) return;

            if (text.isEmpty) {
              // Allow empty during typing
              widget.onChanged(0);
              return;
            }

            // Parse the value
            final val = int.tryParse(text);
            if (val != null) {
              widget.onChanged(val);
            } else {
              // If invalid, revert to previous value
              if (mounted) {
                _controller.text = _formatValue(widget.value);
                _controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: _controller.text.length),
                );
              }
            }
          },
        ),
      ],
    );
  }
}
