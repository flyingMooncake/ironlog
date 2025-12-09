import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/calculations.dart';
import '../../providers/workout_provider.dart';
import '../../repositories/workout_repository.dart';
import '../../services/export_service.dart';

class WorkoutDetailScreen extends ConsumerStatefulWidget {
  final int workoutId;

  const WorkoutDetailScreen({
    super.key,
    required this.workoutId,
  });

  @override
  ConsumerState<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends ConsumerState<WorkoutDetailScreen> {
  final ExportService _exportService = ExportService();
  bool _isExporting = false;

  Future<void> _exportWorkout() async {
    setState(() => _isExporting = true);
    try {
      await _exportService.exportAndShareSingleWorkout(widget.workoutId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout exported successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting workout: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workoutDetailsAsync = ref.watch(workoutDetailsProvider(widget.workoutId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Workout Details'),
        elevation: 0,
        actions: [
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.ios_share),
            onPressed: _isExporting ? null : _exportWorkout,
            tooltip: 'Export workout',
          ),
        ],
      ),
      body: workoutDetailsAsync.when(
        data: (details) {
          if (details == null) {
            return _buildNotFound();
          }
          return _buildWorkoutDetails(context, details);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stack) => _buildError(error),
      ),
    );
  }

  static Widget _buildNotFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          const Text(
            'Workout not found',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildError(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 64),
          const SizedBox(height: 16),
          const Text(
            'Error loading workout',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static Widget _buildWorkoutDetails(BuildContext context, WorkoutDetails details) {
    final session = details.session;
    final exercises = details.exercises;

    final dateStr = DateFormat('EEEE, MMMM d, y').format(session.startedAt);
    final startTime = DateFormat('h:mm a').format(session.startedAt);
    final duration = session.durationMinutes ?? 0;
    final volume = session.totalVolume?.toStringAsFixed(0) ?? '0';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Workout summary card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.name ?? 'Workout',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  dateStr,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(color: AppColors.surfaceHighlight),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn(
                      Icons.access_time,
                      'Duration',
                      '$duration min',
                      AppColors.info,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppColors.surfaceHighlight,
                    ),
                    _buildStatColumn(
                      Icons.fitness_center,
                      'Volume',
                      '$volume kg',
                      AppColors.success,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppColors.surfaceHighlight,
                    ),
                    _buildStatColumn(
                      Icons.alarm,
                      'Started',
                      startTime,
                      AppColors.warning,
                    ),
                  ],
                ),
                if (session.notes != null && session.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.surfaceHighlight),
                  const SizedBox(height: 16),
                  const Text(
                    'Notes',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    session.notes!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Exercises list
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Exercises (${exercises.length})',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Exercise cards
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              return _buildExerciseCard(exercises[index]);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  static Widget _buildStatColumn(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  static Widget _buildExerciseCard(ExerciseWithSets exerciseWithSets) {
    final exercise = exerciseWithSets.exercise;
    final sets = exerciseWithSets.sets;

    // Calculate exercise volume and best 1RM
    double exerciseVolume = 0;
    double? best1RM;
    for (final set in sets) {
      if (!set.isWarmup) {
        exerciseVolume += set.volume;
        if (set.weight != null && set.reps != null) {
          final estimated1RM = calculateEpley1RM(set.weight!, set.reps!);
          if (best1RM == null || estimated1RM > best1RM) {
            best1RM = estimated1RM;
          }
        }
      }
    }

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
                      Row(
                        children: [
                          Text(
                            exercise.primaryMuscle.displayName,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${exerciseVolume.toStringAsFixed(0)} kg',
                            style: const TextStyle(
                              color: AppColors.success,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (best1RM != null) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.info.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '1RM: ${best1RM.toStringAsFixed(0)}kg',
                                style: const TextStyle(
                                  color: AppColors.info,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
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
                SizedBox(
                  width: 40,
                  child: Text(
                    'Set',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Weight',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Reps',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Volume',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          // Sets rows
          ...sets.map((set) => _buildSetRow(set)),

          const SizedBox(height: 4),
        ],
      ),
    );
  }

  static Widget _buildSetRow(workoutSet) {
    // Check if this set is a PR (RPE = 10 means user marked it as PR)
    final isPR = workoutSet.rpe == 10;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceHighlight.withOpacity(0.5), width: 0.5),
        ),
        color: isPR ? AppColors.primary.withOpacity(0.05) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Row(
              children: [
                Text(
                  '${workoutSet.setOrder}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                if (workoutSet.isWarmup)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'W',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (isPR)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'PR',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              workoutSet.weight?.toStringAsFixed(1) ?? '-',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              workoutSet.reps?.toString() ?? '-',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              workoutSet.volume.toStringAsFixed(0),
              style: TextStyle(
                color: workoutSet.isWarmup ? AppColors.textMuted : (isPR ? AppColors.primary : AppColors.success),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
