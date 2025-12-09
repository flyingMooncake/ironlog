import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../models/workout_session.dart';
import '../../models/workout_set.dart';
import '../../models/exercise.dart';
import '../../providers/workout_provider.dart';
import '../../repositories/workout_repository.dart';
import '../../repositories/set_repository.dart';
import '../../repositories/exercise_repository.dart';

class EditWorkoutScreen extends ConsumerStatefulWidget {
  final int workoutId;

  const EditWorkoutScreen({
    super.key,
    required this.workoutId,
  });

  @override
  ConsumerState<EditWorkoutScreen> createState() => _EditWorkoutScreenState();
}

class _EditWorkoutScreenState extends ConsumerState<EditWorkoutScreen> {
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();

  WorkoutSession? _workout;
  List<_ExerciseData> _exercises = [];
  DateTime? _startTime;
  DateTime? _endTime;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadWorkoutData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkoutData() async {
    try {
      final workoutRepo = ref.read(workoutRepositoryProvider);
      final setRepo = SetRepository();
      final exerciseRepo = ExerciseRepository();

      final details = await workoutRepo.getWorkoutDetails(widget.workoutId);

      if (details == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Workout not found'),
              backgroundColor: AppColors.error,
            ),
          );
          context.pop();
        }
        return;
      }

      _workout = details.session;
      _nameController.text = _workout!.name ?? '';
      _notesController.text = _workout!.notes ?? '';
      _startTime = _workout!.startedAt;
      _endTime = _workout!.finishedAt;

      // Convert to editable exercise data
      _exercises = details.exercises.map((e) {
        return _ExerciseData(
          exercise: e.exercise,
          sets: e.sets.map((s) => _SetData.fromWorkoutSet(s)).toList(),
        );
      }).toList();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading workout: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveWorkout() async {
    if (_workout == null || _startTime == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final workoutRepo = ref.read(workoutRepositoryProvider);
      final setRepo = SetRepository();

      // Calculate duration
      final duration = _endTime != null
          ? _endTime!.difference(_startTime!).inMinutes
          : null;

      // Calculate total volume
      double totalVolume = 0;
      for (final exercise in _exercises) {
        for (final set in exercise.sets) {
          if (!set.isWarmup && set.weight != null && set.reps != null) {
            totalVolume += set.weight! * set.reps!;
          }
        }
      }

      // Update workout session
      final updatedWorkout = _workout!.copyWith(
        name: _nameController.text.isEmpty ? null : _nameController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        startedAt: _startTime,
        finishedAt: _endTime,
        durationMinutes: duration,
        totalVolume: totalVolume,
      );

      await workoutRepo.updateWorkoutSession(updatedWorkout);

      // Delete all existing sets and recreate them
      await setRepo.deleteSetsBySessionId(widget.workoutId);

      // Create new sets
      for (final exercise in _exercises) {
        for (int i = 0; i < exercise.sets.length; i++) {
          final setData = exercise.sets[i];
          final set = WorkoutSet(
            sessionId: widget.workoutId,
            exerciseId: exercise.exercise.id!,
            setOrder: i + 1,
            weight: setData.weight,
            reps: setData.reps,
            durationSeconds: setData.durationSeconds,
            rpe: setData.rpe,
            isWarmup: setData.isWarmup,
            isDropSet: setData.isDropSet,
            notes: setData.notes,
            completedAt: setData.completedAt ?? DateTime.now(),
          );
          await setRepo.createSet(set);
        }
      }

      // Invalidate providers to refresh the UI
      ref.invalidate(workoutDetailsProvider(widget.workoutId));
      ref.invalidate(workoutSessionsByDateProvider(_startTime!));
      ref.invalidate(workoutSessionsGroupedProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving workout: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _selectDateTime(bool isStart) async {
    final initialDate = isStart
        ? (_startTime ?? DateTime.now())
        : (_endTime ?? _startTime ?? DateTime.now());

    // Select date
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date == null) return;

    // Select time
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time == null) return;

    final dateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      if (isStart) {
        _startTime = dateTime;
        // If end time is before start time, adjust it
        if (_endTime != null && _endTime!.isBefore(_startTime!)) {
          _endTime = _startTime;
        }
      } else {
        _endTime = dateTime;
        // If end time is before start time, swap them
        if (_endTime!.isBefore(_startTime!)) {
          final temp = _startTime;
          _startTime = _endTime;
          _endTime = temp;
        }
      }
    });
  }

  Future<void> _addExercise() async {
    final exerciseRepo = ExerciseRepository();
    final allExercises = await exerciseRepo.getAllExercises();

    // Filter out already added exercises
    final availableExercises = allExercises.where((e) {
      return !_exercises.any((ex) => ex.exercise.id == e.id);
    }).toList();

    if (!mounted) return;

    final selected = await showDialog<Exercise>(
      context: context,
      builder: (context) => _ExercisePickerDialog(exercises: availableExercises),
    );

    if (selected != null) {
      setState(() {
        _exercises.add(_ExerciseData(
          exercise: selected,
          sets: [_SetData.empty()],
        ));
      });
    }
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
    });
  }

  void _addSet(int exerciseIndex) {
    setState(() {
      final exercise = _exercises[exerciseIndex];
      // Copy from last set if available
      if (exercise.sets.isNotEmpty) {
        final lastSet = exercise.sets.last;
        exercise.sets.add(_SetData(
          weight: lastSet.weight,
          reps: lastSet.reps,
          durationSeconds: lastSet.durationSeconds,
          rpe: lastSet.rpe,
          isWarmup: false,
          isDropSet: false,
        ));
      } else {
        exercise.sets.add(_SetData.empty());
      }
    });
  }

  void _removeSet(int exerciseIndex, int setIndex) {
    setState(() {
      _exercises[exerciseIndex].sets.removeAt(setIndex);
      // Remove exercise if no sets left
      if (_exercises[exerciseIndex].sets.isEmpty) {
        _exercises.removeAt(exerciseIndex);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Edit Workout'),
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final duration = _startTime != null && _endTime != null
        ? _endTime!.difference(_startTime!).inMinutes
        : 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Workout'),
        elevation: 0,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveWorkout,
              tooltip: 'Save',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Workout info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      hintText: 'Workout Name',
                      hintStyle: TextStyle(color: AppColors.textMuted),
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.surfaceHighlight),
                  const SizedBox(height: 16),

                  // Date and time
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDateTime(true),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Start Time',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _startTime != null
                                      ? DateFormat('MMM d, h:mm a').format(_startTime!)
                                      : 'Not set',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDateTime(false),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'End Time',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _endTime != null
                                      ? DateFormat('MMM d, h:mm a').format(_endTime!)
                                      : 'Not set',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Duration display
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer, color: AppColors.info, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Duration: $duration min',
                          style: const TextStyle(
                            color: AppColors.info,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: AppColors.surfaceHighlight),
                  const SizedBox(height: 16),

                  // Notes
                  TextField(
                    controller: _notesController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Notes (optional)',
                      hintStyle: const TextStyle(color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.surfaceElevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Exercises
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Exercises',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addExercise,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Exercise'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Exercise list
            if (_exercises.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'No exercises added yet',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            else
              ...List.generate(_exercises.length, (index) {
                return _buildExerciseCard(index);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(int exerciseIndex) {
    final exerciseData = _exercises[exerciseIndex];
    final exercise = exerciseData.exercise;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        exercise.primaryMuscle.displayName,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  onPressed: () => _removeExercise(exerciseIndex),
                  tooltip: 'Remove exercise',
                ),
              ],
            ),
          ),

          // Sets table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.surfaceElevated,
            child: Row(
              children: const [
                SizedBox(width: 40, child: Text('Set', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600))),
                Expanded(child: Text('Weight (kg)', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                Expanded(child: Text('Reps', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                SizedBox(width: 60, child: Text('Warmup', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                SizedBox(width: 48),
              ],
            ),
          ),

          // Sets rows
          ...List.generate(exerciseData.sets.length, (setIndex) {
            return _buildSetRow(exerciseIndex, setIndex);
          }),

          // Add set button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _addSet(exerciseIndex),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Set'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetRow(int exerciseIndex, int setIndex) {
    final setData = _exercises[exerciseIndex].sets[setIndex];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.surfaceHighlight.withOpacity(0.5),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Set number
          SizedBox(
            width: 40,
            child: Text(
              '${setIndex + 1}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Weight input
          Expanded(
            child: TextField(
              controller: TextEditingController(
                text: setData.weight?.toStringAsFixed(1) ?? '',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: '-',
                hintStyle: TextStyle(color: AppColors.textMuted),
              ),
              onChanged: (value) {
                setData.weight = double.tryParse(value);
              },
            ),
          ),

          // Reps input
          Expanded(
            child: TextField(
              controller: TextEditingController(
                text: setData.reps?.toString() ?? '',
              ),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: '-',
                hintStyle: TextStyle(color: AppColors.textMuted),
              ),
              onChanged: (value) {
                setData.reps = int.tryParse(value);
              },
            ),
          ),

          // Warmup checkbox
          SizedBox(
            width: 60,
            child: Checkbox(
              value: setData.isWarmup,
              onChanged: (value) {
                setState(() {
                  setData.isWarmup = value ?? false;
                });
              },
              activeColor: AppColors.primary,
            ),
          ),

          // Delete button
          SizedBox(
            width: 48,
            child: IconButton(
              icon: const Icon(Icons.close, color: AppColors.error, size: 20),
              onPressed: () => _removeSet(exerciseIndex, setIndex),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}

// Helper class for exercise data
class _ExerciseData {
  final Exercise exercise;
  final List<_SetData> sets;

  _ExerciseData({
    required this.exercise,
    required this.sets,
  });
}

// Helper class for set data
class _SetData {
  double? weight;
  int? reps;
  int? durationSeconds;
  int? rpe;
  bool isWarmup;
  bool isDropSet;
  String? notes;
  DateTime? completedAt;

  _SetData({
    this.weight,
    this.reps,
    this.durationSeconds,
    this.rpe,
    this.isWarmup = false,
    this.isDropSet = false,
    this.notes,
    this.completedAt,
  });

  factory _SetData.empty() {
    return _SetData();
  }

  factory _SetData.fromWorkoutSet(WorkoutSet set) {
    return _SetData(
      weight: set.weight,
      reps: set.reps,
      durationSeconds: set.durationSeconds,
      rpe: set.rpe,
      isWarmup: set.isWarmup,
      isDropSet: set.isDropSet,
      notes: set.notes,
      completedAt: set.completedAt,
    );
  }
}

// Exercise picker dialog
class _ExercisePickerDialog extends StatefulWidget {
  final List<Exercise> exercises;

  const _ExercisePickerDialog({required this.exercises});

  @override
  State<_ExercisePickerDialog> createState() => _ExercisePickerDialogState();
}

class _ExercisePickerDialogState extends State<_ExercisePickerDialog> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredExercises = widget.exercises.where((e) {
      return e.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Dialog(
      backgroundColor: AppColors.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Select Exercise',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search exercises...',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: filteredExercises.length,
              itemBuilder: (context, index) {
                final exercise = filteredExercises[index];
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
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }
}
