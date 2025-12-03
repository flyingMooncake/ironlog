import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../models/exercise.dart';
import '../../models/workout_session.dart';
import '../../models/workout_set.dart';
import '../../providers/exercise_provider.dart';
import '../../providers/rest_timer_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/template_provider.dart';
import '../../repositories/workout_repository.dart';
import '../../repositories/set_repository.dart';
import '../../repositories/target_repository.dart';
import '../../repositories/personal_record_repository.dart';
import '../../services/haptic_service.dart';
import '../../services/workout_persistence_service.dart';
import '../../widgets/rest_timer_widget.dart';
import '../../models/workout_set.dart' as models;

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? initialData;

  const ActiveWorkoutScreen({super.key, this.initialData});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> with WidgetsBindingObserver {
  final List<WorkoutExerciseUI> _workoutExercises = [];
  late DateTime _workoutStartTime;
  String? _workoutNotes;
  final WorkoutRepository _workoutRepo = WorkoutRepository();
  final SetRepository _setRepo = SetRepository();
  final PersonalRecordRepository _prRepo = PersonalRecordRepository();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _workoutStartTime = DateTime.now();
    _loadInitialData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // App going to background - save workout state
      _saveWorkoutState();
    } else if (state == AppLifecycleState.resumed) {
      // App coming back from background - restore if needed
      _restoreWorkoutState();
    }
  }

  Future<void> _saveWorkoutState() async {
    if (_workoutExercises.isEmpty) return;

    final workoutData = {
      'startTime': _workoutStartTime.toIso8601String(),
      'notes': _workoutNotes,
      'exercises': _workoutExercises.map((e) => {
        'exerciseId': e.exercise.id,
        'exerciseName': e.exercise.name,
        'sets': e.sets.map((s) => {
          'weight': s.weight,
          'reps': s.reps,
          'time': s.time,
          'isWarmup': s.isWarmup,
        }).toList(),
      }).toList(),
    };

    await WorkoutPersistenceService.saveWorkoutDraft(workoutData);
  }

  Future<void> _restoreWorkoutState() async {
    // Only restore if current workout is empty
    if (_workoutExercises.isNotEmpty) return;

    final saved = await WorkoutPersistenceService.loadWorkoutDraft();
    if (saved == null) return;

    // Don't auto-restore, let user decide
    // The data is there if they navigate back
  }

  Future<void> _loadInitialData() async {
    if (widget.initialData == null) return;

    try {
      final type = widget.initialData!['type'] as String?;

      if (type == 'template') {
        await _loadFromTemplate(widget.initialData!['templateId'] as int);
      } else if (type == 'history') {
        await _loadFromHistory(widget.initialData!['sessionId'] as int);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading workout: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _loadFromTemplate(int templateId) async {
    final repo = ref.read(templateRepositoryProvider);
    final template = await repo.getTemplate(templateId);

    if (template == null) return;

    final exerciseRepo = ref.read(exerciseRepositoryProvider);

    for (final templateExercise in template.exercises) {
      final exercise = await exerciseRepo.getExerciseById(templateExercise.exerciseId);
      if (exercise != null) {
        final sets = List.generate(
          templateExercise.sets,
          (index) => WorkoutSetUI(
            weight: templateExercise.targetWeight,
            reps: templateExercise.targetReps,
            isWarmup: false,
          ),
        );

        setState(() {
          _workoutExercises.add(WorkoutExerciseUI(
            exercise: exercise,
            sets: sets,
          ));
        });
      }
    }
  }

  Future<void> _loadFromHistory(int sessionId) async {
    final details = await _workoutRepo.getWorkoutDetails(sessionId);
    if (details == null) return;

    _workoutNotes = details.session.notes;

    for (final exerciseWithSets in details.exercises) {
      final sets = exerciseWithSets.sets.map((set) => WorkoutSetUI(
        weight: set.weight,
        reps: set.reps,
        isWarmup: set.isWarmup,
        notes: set.notes,
      )).toList();

      setState(() {
        _workoutExercises.add(WorkoutExerciseUI(
          exercise: exerciseWithSets.exercise,
          sets: sets,
        ));
      });
    }
  }

  void _addExercise() async {
    final selectedExercise = await showDialog<Exercise>(
      context: context,
      builder: (context) => const ExercisePickerDialog(),
    );

    if (selectedExercise != null) {
      setState(() {
        _workoutExercises.add(WorkoutExerciseUI(exercise: selectedExercise));
      });
    }
  }

  void _addSet(int exerciseIndex) {
    HapticService.instance.medium();
    setState(() {
      _workoutExercises[exerciseIndex].sets.add(WorkoutSetUI());
    });
  }

  void _checkAndStartRestTimer(WorkoutSetUI set) async {
    // Only auto-start if both weight and reps are filled
    if (set.weight == null || set.reps == null) return;

    final profile = await ref.read(userProfileProvider.future);
    if (profile.autoStartRestTimer) {
      ref.read(restTimerProvider.notifier).startTimer(profile.restTimerDefault);
    }
  }

  void _removeExercise(int index) {
    setState(() {
      _workoutExercises.removeAt(index);
    });
  }

  String _generateSupersetId() {
    return 'SS_${DateTime.now().millisecondsSinceEpoch}';
  }

  void _createSupersetWithNext(int exerciseIndex) {
    if (exerciseIndex >= _workoutExercises.length - 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot create superset: no exercise below'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final currentExercise = _workoutExercises[exerciseIndex];
    final nextExercise = _workoutExercises[exerciseIndex + 1];

    // If next exercise already has a superset, join that one
    final supersetId = nextExercise.supersetId ?? _generateSupersetId();

    setState(() {
      currentExercise.supersetId = supersetId;
      nextExercise.supersetId = supersetId;
    });

    HapticService.instance.medium();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Superset created'),
        duration: Duration(seconds: 1),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _removeFromSuperset(int exerciseIndex) {
    final exercise = _workoutExercises[exerciseIndex];
    if (exercise.supersetId == null) return;

    final supersetId = exercise.supersetId;

    setState(() {
      exercise.supersetId = null;

      // If only one exercise left in superset, remove its superset ID too
      final remainingInSuperset = _workoutExercises.where((e) => e.supersetId == supersetId).toList();
      if (remainingInSuperset.length == 1) {
        remainingInSuperset.first.supersetId = null;
      }
    });

    HapticService.instance.light();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Removed from superset'),
        duration: Duration(seconds: 1),
        backgroundColor: AppColors.info,
      ),
    );
  }

  Future<void> _onBackPressed() async {
    if (_workoutExercises.isEmpty) {
      // No exercises, just go back to previous page or home
      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      }
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Discard Workout?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to discard this workout? All progress will be lost.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Keep Editing',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Discard',
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Clear the workout draft
      await WorkoutPersistenceService.clearWorkoutDraft();

      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      }
    }
  }

  void _finishWorkout() async {
    if (_workoutExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one exercise to save workout'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Calculate duration
    final finishedAt = DateTime.now();
    final durationMinutes = finishedAt.difference(_workoutStartTime).inMinutes;

    // Create workout session
    final session = WorkoutSession(
      startedAt: _workoutStartTime,
      finishedAt: finishedAt,
      durationMinutes: durationMinutes,
      totalVolume: 0, // Will calculate after
      notes: _workoutNotes,
    );

    try {
      // Save session to database
      final sessionId = await _workoutRepo.createWorkoutSession(session);

      // Track PRs - collect all PRs found
      final allPRs = <Map<String, dynamic>>[];

      // Save all sets and check for PRs
      double totalVolume = 0;
      for (final workoutExercise in _workoutExercises) {
        for (int i = 0; i < workoutExercise.sets.length; i++) {
          final setUI = workoutExercise.sets[i];

          // Skip empty sets
          if (setUI.weight == null && setUI.reps == null) continue;

          // For drop sets, format the notes to include all stages
          String? setNotes = setUI.notes;
          if (setUI.isDropSet && setUI.dropSetStages.isNotEmpty) {
            final dropStagesText = setUI.dropSetStages
                .where((stage) => stage.weight != null && stage.reps != null)
                .map((stage) => '${stage.weight}kg × ${stage.reps}')
                .join(' → ');
            if (dropStagesText.isNotEmpty) {
              setNotes = setNotes != null && setNotes.isNotEmpty
                  ? '$setNotes\nDrops: $dropStagesText'
                  : 'Drops: $dropStagesText';
            }
          }

          final set = WorkoutSet(
            sessionId: sessionId,
            exerciseId: workoutExercise.exercise.id!,
            setOrder: i + 1,
            weight: setUI.weight,
            reps: setUI.reps,
            isWarmup: setUI.isWarmup,
            isDropSet: setUI.isDropSet,
            supersetId: workoutExercise.supersetId, // Use exercise's supersetId, not individual set
            notes: setNotes,
          );

          final setId = await _setRepo.createSet(set);

          // Automatically check for PRs on every non-warmup, non-drop set with weight and reps
          if (!setUI.isWarmup && !setUI.isDropSet && set.weight != null && set.reps != null) {
            final newPRs = await _prRepo.checkAndUpdatePRs(
              workoutExercise.exercise.id!,
              set.weight!,
              set.reps!,
              setId,
            );

            // Add any new PRs to the list for display
            for (final pr in newPRs) {
              allPRs.add({
                'exercise': workoutExercise.exercise.name,
                'type': pr.recordType,
                'weight': set.weight,
                'reps': set.reps,
                'value': pr.value,
              });
            }
          }

          // Calculate volume (excluding warmup sets)
          if (!set.isWarmup && set.weight != null && set.reps != null) {
            totalVolume += set.weight! * set.reps!;
            // Add drop set stages to volume
            if (setUI.isDropSet) {
              for (final stage in setUI.dropSetStages) {
                if (stage.weight != null && stage.reps != null) {
                  totalVolume += stage.weight! * stage.reps!;
                }
              }
            }
          }
        }
      }

      // Update session with total volume
      final updatedSession = session.copyWith(
        id: sessionId,
        totalVolume: totalVolume,
      );
      await _workoutRepo.updateWorkoutSession(updatedSession);

      // Update goal progress for all exercises in the workout
      final targetRepo = TargetRepository();
      final exercisesInWorkout = _workoutExercises.map((e) => e.exercise.id!).toSet();
      for (final exerciseId in exercisesInWorkout) {
        await targetRepo.updateTargetProgress(exerciseId);
      }

      // Clear the workout draft since it's now saved
      await WorkoutPersistenceService.clearWorkoutDraft();

      if (!mounted) return;

      // Haptic feedback for workout completion
      if (allPRs.isNotEmpty) {
        // Success pattern for PRs
        await HapticService.instance.success();
      } else {
        // Heavy feedback for normal completion
        await HapticService.instance.heavy();
      }

      // Show success dialog with PR celebration
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Row(
            children: [
              if (allPRs.isNotEmpty) ...[
                const Icon(Icons.celebration, color: AppColors.warning, size: 28),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  allPRs.isNotEmpty ? 'New Personal Records!' : 'Workout Complete!',
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (allPRs.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.success.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Congratulations! You set new PRs:',
                          style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...allPRs.map((pr) {
                          String prText = '• ${pr['exercise']} - ';
                          switch (pr['type']) {
                            case '1rm':
                              prText += 'Est. 1RM: ${pr['value'].toStringAsFixed(1)}kg';
                              break;
                            case 'max_weight':
                              prText += 'Max Weight: ${pr['weight']}kg';
                              break;
                            case 'max_reps':
                              prText += 'Max Reps: ${pr['reps']} reps';
                              break;
                            case 'max_volume':
                              prText += 'Max Volume: ${pr['value'].toStringAsFixed(0)}kg';
                              break;
                          }
                          prText += ' (${pr['weight']}kg × ${pr['reps']})';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              prText,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              const Text(
                'Great job! Your workout has been saved.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Text(
                'Duration: $durationMinutes minutes',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Total Volume: ${totalVolume.toStringAsFixed(0)} kg',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
              child: const Text('OK', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving workout: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          await _onBackPressed();
        }
      },
      child: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping outside
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
        title: const Text('Active Workout'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: _onBackPressed,
          tooltip: 'Cancel Workout',
        ),
        actions: [
          IconButton(
            onPressed: _addWorkoutNotes,
            icon: Icon(
              _workoutNotes != null && _workoutNotes!.isNotEmpty
                  ? Icons.note
                  : Icons.note_outlined,
              color: AppColors.textPrimary,
            ),
            tooltip: 'Workout Notes',
          ),
          IconButton(
            onPressed: _startRestTimer,
            icon: const Icon(Icons.timer, color: AppColors.textPrimary),
            tooltip: 'Start Rest Timer',
          ),
          if (_workoutExercises.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: ElevatedButton.icon(
                onPressed: _finishWorkout,
                icon: const Icon(Icons.check, size: 20),
                label: const Text('Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _workoutExercises.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                    ),
                    itemCount: _workoutExercises.length,
                    itemBuilder: (context, index) {
                      return _buildExerciseCard(_workoutExercises[index], index);
                    },
                  ),
          ),
          const RestTimerWidget(),
        ],
      ),
      floatingActionButton: MediaQuery.of(context).viewInsets.bottom > 0
          ? null // Hide FAB when keyboard is open
          : FloatingActionButton.extended(
              onPressed: _addExercise,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add),
              label: const Text('Add Exercise'),
            ),
        ),
      ),
    );
  }

  void _startRestTimer() async {
    HapticService.instance.medium();
    // Get default rest time from user profile
    final restTime = await ref.read(restTimerDefaultProvider.future);
    ref.read(restTimerProvider.notifier).startTimer(restTime);
  }

  void _addWorkoutNotes() {
    final controller = TextEditingController(text: _workoutNotes ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Workout Notes',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          maxLines: 5,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'How did this workout feel? Any observations?',
            hintStyle: const TextStyle(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surfaceElevated,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _workoutNotes = controller.text.isEmpty ? null : controller.text;
              });
              Navigator.pop(context);
              HapticService.instance.light();
            },
            child: const Text('Save', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  void _addSetNotes(int exerciseIndex, int setIndex) {
    final set = _workoutExercises[exerciseIndex].sets[setIndex];
    final controller = TextEditingController(text: set.notes ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Set Notes',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g., "Felt strong", "Used straps", "Lower back tight"',
            hintStyle: const TextStyle(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surfaceElevated,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          if (set.notes != null && set.notes!.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() {
                  set.notes = null;
                });
                Navigator.pop(context);
                HapticService.instance.light();
              },
              child: const Text('Clear', style: TextStyle(color: AppColors.error)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                set.notes = controller.text.isEmpty ? null : controller.text;
              });
              Navigator.pop(context);
              HapticService.instance.light();
            },
            child: const Text('Save', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
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
            'No exercises added yet',
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

  Widget _buildExerciseCard(WorkoutExerciseUI workoutExercise, int exerciseIndex) {
    final bool isInSuperset = workoutExercise.supersetId != null;
    final bool isFirstInSuperset = isInSuperset &&
        (exerciseIndex == 0 || _workoutExercises[exerciseIndex - 1].supersetId != workoutExercise.supersetId);
    final bool isLastInSuperset = isInSuperset &&
        (exerciseIndex == _workoutExercises.length - 1 || _workoutExercises[exerciseIndex + 1].supersetId != workoutExercise.supersetId);

    return Container(
      margin: EdgeInsets.only(
        bottom: isInSuperset && !isLastInSuperset ? 4 : 16,
        left: isInSuperset ? 8 : 0,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: isInSuperset ? Border.all(
          color: AppColors.primary.withOpacity(0.5),
          width: 2,
        ) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Superset label (only on first exercise in superset)
          if (isInSuperset && isFirstInSuperset)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.link, size: 14, color: AppColors.primary),
                  SizedBox(width: 4),
                  Text(
                    'SUPERSET',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
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
                        workoutExercise.exercise.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        workoutExercise.exercise.primaryMuscle.displayName,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _PreviousWorkoutData(exerciseId: workoutExercise.exercise.id!),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
                  color: AppColors.surface,
                  onSelected: (value) {
                    switch (value) {
                      case 'superset':
                        _createSupersetWithNext(exerciseIndex);
                        break;
                      case 'remove_superset':
                        _removeFromSuperset(exerciseIndex);
                        break;
                      case 'delete':
                        _removeExercise(exerciseIndex);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    if (!isInSuperset)
                      PopupMenuItem(
                        value: 'superset',
                        child: Row(
                          children: [
                            Icon(Icons.link, size: 18, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text('Create Superset', style: TextStyle(color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                    if (isInSuperset)
                      PopupMenuItem(
                        value: 'remove_superset',
                        child: Row(
                          children: [
                            Icon(Icons.link_off, size: 18, color: AppColors.warning),
                            SizedBox(width: 8),
                            Text('Remove from Superset', style: TextStyle(color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                          SizedBox(width: 8),
                          Text('Delete Exercise', style: TextStyle(color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Sets header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.surfaceElevated,
            child: Row(
              children: const [
                SizedBox(width: 40, child: Text('Set', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600))),
                SizedBox(width: 40, child: Text('D', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                Expanded(child: Text('Weight (kg)', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                Expanded(child: Text('Reps', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                SizedBox(width: 32),
                SizedBox(width: 40),
              ],
            ),
          ),
          // Sets
          ...workoutExercise.sets.asMap().entries.map((entry) {
            final setIndex = entry.key;
            final set = entry.value;
            return _buildSetRow(exerciseIndex, setIndex, set);
          }),
          // Add set button
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _addSet(exerciseIndex),
                icon: const Icon(Icons.add, color: AppColors.primary, size: 20),
                label: const Text(
                  'Add Set',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetRow(int exerciseIndex, int setIndex, WorkoutSetUI set) {
    Color backgroundColor = Colors.transparent;
    if (set.isWarmup) {
      backgroundColor = AppColors.warning.withOpacity(0.05);
    } else if (set.isDropSet) {
      backgroundColor = AppColors.error.withOpacity(0.05);
    }

    return GestureDetector(
      onDoubleTap: () {
        HapticService.instance.medium();
        setState(() {
          set.isWarmup = !set.isWarmup;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(
            bottom: BorderSide(color: AppColors.surfaceHighlight, width: 1),
          ),
        ),
        child: Column(
          children: [
            // Main set row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Row(
                      children: [
                        if (set.isWarmup)
                          Container(
                            width: 4,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.warning,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            margin: const EdgeInsets.only(right: 4),
                          ),
                        Expanded(
                          child: Text(
                            '${setIndex + 1}',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: GestureDetector(
                      onTap: () {
                        HapticService.instance.light();
                        setState(() {
                          set.isDropSet = !set.isDropSet;
                          // When enabling drop set, add first stage if none exist
                          if (set.isDropSet && set.dropSetStages.isEmpty) {
                            set.dropSetStages.add(DropSetStage());
                          }
                        });
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: set.isDropSet ? AppColors.error : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: set.isDropSet ? AppColors.error : AppColors.textMuted.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'D',
                            style: TextStyle(
                              color: set.isDropSet ? Colors.white : AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildWeightInput(
                      exerciseIndex: exerciseIndex,
                      setIndex: setIndex,
                      set: set,
                    ),
                  ),
                  Expanded(
                    child: _RepsTextField(
                      reps: set.reps,
                      onChanged: (value) {
                        setState(() {
                          set.reps = value;
                        });
                        if (value != null && set.weight != null) {
                          _checkAndStartRestTimer(set);
                        }
                      },
                    ),
                  ),
                  SizedBox(
                    width: 32,
                    child: IconButton(
                      onPressed: () => _addSetNotes(exerciseIndex, setIndex),
                      icon: Icon(
                        set.notes != null && set.notes!.isNotEmpty
                            ? Icons.note
                            : Icons.note_outlined,
                        color: AppColors.textMuted,
                        size: 18,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Add note',
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          _workoutExercises[exerciseIndex].sets.removeAt(setIndex);
                        });
                      },
                      icon: const Icon(Icons.delete_outline, color: AppColors.textMuted, size: 20),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
            // Drop set stages
            if (set.isDropSet) ...[
              ...set.dropSetStages.asMap().entries.map((entry) {
                final stageIndex = entry.key;
                final stage = entry.value;
                return _buildDropSetStage(exerciseIndex, setIndex, stageIndex, stage);
              }),
              // Add drop set stage button
              Padding(
                padding: const EdgeInsets.only(left: 56, right: 16, bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      HapticService.instance.light();
                      setState(() {
                        set.dropSetStages.add(DropSetStage());
                      });
                    },
                    icon: const Icon(Icons.add, color: AppColors.error, size: 16),
                    label: const Text(
                      'Add Drop',
                      style: TextStyle(color: AppColors.error, fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDropSetStage(int exerciseIndex, int setIndex, int stageIndex, DropSetStage stage) {
    return Padding(
      padding: const EdgeInsets.only(left: 56, right: 16, bottom: 8),
      child: Row(
        children: [
          Icon(Icons.arrow_right, size: 16, color: AppColors.error.withOpacity(0.6)),
          const SizedBox(width: 8),
          Expanded(
            child: _WeightTextField(
              weight: stage.weight,
              onChanged: (value) {
                setState(() {
                  stage.weight = value;
                });
              },
              onIncrement: () {
                HapticService.instance.light();
                setState(() {
                  final current = stage.weight ?? 0;
                  stage.weight = current + 0.5;
                });
              },
              onDecrement: () {
                HapticService.instance.light();
                setState(() {
                  final current = stage.weight ?? 0;
                  stage.weight = (current - 0.5).clamp(0, double.infinity);
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _RepsTextField(
              reps: stage.reps,
              onChanged: (value) {
                setState(() {
                  stage.reps = value;
                });
              },
            ),
          ),
          SizedBox(
            width: 72, // Match the width of notes + delete buttons
            child: IconButton(
              onPressed: () {
                setState(() {
                  _workoutExercises[exerciseIndex].sets[setIndex].dropSetStages.removeAt(stageIndex);
                });
              },
              icon: const Icon(Icons.remove_circle_outline, color: AppColors.textMuted, size: 18),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightInput({
    required int exerciseIndex,
    required int setIndex,
    required WorkoutSetUI set,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: _WeightTextField(
        weight: set.weight,
        onChanged: (value) {
          setState(() {
            set.weight = value;
          });
          if (value != null && set.reps != null) {
            _checkAndStartRestTimer(set);
          }
        },
        onIncrement: () {
          HapticService.instance.light();
          setState(() {
            final current = set.weight ?? 0;
            set.weight = current + 0.5;
          });
        },
        onDecrement: () {
          HapticService.instance.light();
          setState(() {
            final current = set.weight ?? 0;
            set.weight = (current - 0.5).clamp(0, double.infinity);
          });
        },
      ),
    );
  }

}

// UI models (temporary state before saving to DB)
class WorkoutExerciseUI {
  final Exercise exercise;
  final List<WorkoutSetUI> sets;
  String? supersetId;

  WorkoutExerciseUI({
    required this.exercise,
    List<WorkoutSetUI>? sets,
    this.supersetId,
  }) : sets = sets ?? [];
}

class DropSetStage {
  double? weight;
  int? reps;

  DropSetStage({this.weight, this.reps});
}

class WorkoutSetUI {
  double? weight;
  int? reps;
  bool isWarmup;
  bool isDropSet;
  String? notes;
  List<DropSetStage> dropSetStages;

  WorkoutSetUI({
    this.weight,
    this.reps,
    this.isWarmup = false,
    this.isDropSet = false,
    this.notes,
    List<DropSetStage>? dropSetStages,
  }) : dropSetStages = dropSetStages ?? [];
}

// Widget to show previous workout data for an exercise
class _PreviousWorkoutData extends ConsumerWidget {
  final int exerciseId;

  const _PreviousWorkoutData({required this.exerciseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<models.WorkoutSet>>(
      future: _setRepo.getLastWorkoutSetsForExercise(exerciseId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final lastSets = snapshot.data!;
        final summary = _formatLastWorkout(lastSets);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.history, size: 14, color: AppColors.info),
              const SizedBox(width: 4),
              Text(
                'Last: $summary',
                style: const TextStyle(
                  color: AppColors.info,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static final _setRepo = SetRepository();

  String _formatLastWorkout(List<models.WorkoutSet> sets) {
    if (sets.isEmpty) return 'No previous data';

    // Show up to 3 sets
    final setsToShow = sets.take(3).toList();
    final formatted = setsToShow
        .map((set) => '${set.weight?.toStringAsFixed(0) ?? '?'}kg × ${set.reps ?? '?'}')
        .join(', ');

    return sets.length > 3 ? '$formatted +${sets.length - 3}' : formatted;
  }
}

class ExercisePickerDialog extends ConsumerStatefulWidget {
  const ExercisePickerDialog({super.key});

  @override
  ConsumerState<ExercisePickerDialog> createState() => _ExercisePickerDialogState();
}

class _ExercisePickerDialogState extends ConsumerState<ExercisePickerDialog> {
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

    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside search field
        FocusScope.of(context).unfocus();
      },
      child: Dialog(
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
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.textMuted),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(exerciseFilterProvider.notifier).setSearchQuery(null);
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() {}); // Rebuild to show/hide clear button
                  ref
                      .read(exerciseFilterProvider.notifier)
                      .setSearchQuery(value.isEmpty ? null : value);
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: exercisesAsync.when(
                  data: (exercises) {
                    if (exercises.isEmpty) {
                      return const Center(
                        child: Text(
                          'No exercises found',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: exercises.length,
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      itemBuilder: (context, index) {
                        final exercise = exercises[index];
                        return _ExerciseWithHistory(
                          exercise: exercise,
                          onTap: () => Navigator.pop(context, exercise),
                        );
                      },
                    );
                  },
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
      ),
    );
  }
}

class _ExerciseWithHistory extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onTap;

  const _ExerciseWithHistory({
    required this.exercise,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final setRepo = SetRepository();

    return FutureBuilder<models.WorkoutSet?>(
      future: setRepo.getLastSetForExercise(exercise.id!),
      builder: (context, snapshot) {
        String? lastWorkout;
        if (snapshot.hasData && snapshot.data != null) {
          final set = snapshot.data!;
          lastWorkout = 'Last: ${set.weight}kg × ${set.reps} reps';
        }

        return ListTile(
          title: Text(
            exercise.name,
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                exercise.primaryMuscle.displayName,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              if (lastWorkout != null) ...[
                const SizedBox(height: 2),
                Text(
                  lastWorkout,
                  style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ],
          ),
          onTap: onTap,
        );
      },
    );
  }
}

class _RepsTextField extends StatefulWidget {
  final int? reps;
  final ValueChanged<int?> onChanged;

  const _RepsTextField({
    required this.reps,
    required this.onChanged,
  });

  @override
  State<_RepsTextField> createState() => _RepsTextFieldState();
}

class _RepsTextFieldState extends State<_RepsTextField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.reps?.toString() ?? '');
  }

  @override
  void didUpdateWidget(_RepsTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reps != oldWidget.reps) {
      final currentValue = int.tryParse(_controller.text);
      if (currentValue != widget.reps) {
        _controller.text = widget.reps?.toString() ?? '';
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextField(
        controller: _controller,
        onChanged: (value) {
          // Remove leading zeros
          if (value.isNotEmpty && value.startsWith('0') && value.length > 1) {
            final newValue = value.replaceFirst(RegExp(r'^0+'), '');
            _controller.value = TextEditingValue(
              text: newValue,
              selection: TextSelection.collapsed(offset: newValue.length),
            );
            widget.onChanged(int.tryParse(newValue));
          } else {
            widget.onChanged(int.tryParse(value));
          }
        },
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
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
      ),
    );
  }
}

class _WeightTextField extends StatefulWidget {
  final double? weight;
  final ValueChanged<double?> onChanged;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _WeightTextField({
    required this.weight,
    required this.onChanged,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  State<_WeightTextField> createState() => _WeightTextFieldState();
}

class _WeightTextFieldState extends State<_WeightTextField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatWeight(widget.weight));
  }

  @override
  void didUpdateWidget(_WeightTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update if value changed externally (e.g., from +/- buttons)
    if (widget.weight != oldWidget.weight) {
      final currentValue = double.tryParse(_controller.text.replaceAll(',', '.'));
      // Only update if the values are actually different (not just formatting)
      if (currentValue != widget.weight) {
        _controller.text = _formatWeight(widget.weight);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatWeight(double? weight) {
    if (weight == null) return '';
    // Remove trailing .0 for whole numbers
    if (weight == weight.roundToDouble()) {
      return weight.toInt().toString();
    }
    return weight.toString();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        // Swipe up to increment, swipe down to decrement
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -300) {
            // Swipe up (negative velocity)
            FocusScope.of(context).unfocus();
            widget.onIncrement();
          } else if (details.primaryVelocity! > 300) {
            // Swipe down (positive velocity)
            FocusScope.of(context).unfocus();
            widget.onDecrement();
          }
        }
      },
      child: TextField(
        controller: _controller,
        onChanged: (value) {
          // Replace comma with period for decimal input
          var normalizedValue = value.replaceAll(',', '.');

          // Replace multiple consecutive dots with single dot
          normalizedValue = normalizedValue.replaceAll(RegExp(r'\.{2,}'), '.');

          // Remove extra decimal points (keep only the first one)
          final parts = normalizedValue.split('.');
          if (parts.length > 2) {
            normalizedValue = '${parts[0]}.${parts.sublist(1).join('')}';
          }

          // Remove leading zeros except for decimal values like "0.5"
          if (normalizedValue.isNotEmpty &&
              normalizedValue.startsWith('0') &&
              normalizedValue.length > 1 &&
              !normalizedValue.startsWith('0.')) {
            normalizedValue = normalizedValue.replaceFirst(RegExp(r'^0+'), '');
            if (normalizedValue.isEmpty || normalizedValue.startsWith('.')) {
              normalizedValue = '0$normalizedValue';
            }
          }

          if (normalizedValue != value) {
            _controller.text = normalizedValue;
            _controller.selection = TextSelection.fromPosition(
              TextPosition(offset: normalizedValue.length),
            );
          }
          widget.onChanged(double.tryParse(normalizedValue));
        },
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
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
      ),
    );
  }
}
