import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../models/workout_session.dart';
import '../../providers/workout_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  void _editWorkout(WorkoutSession workout) async {
    final nameController = TextEditingController(text: workout.name);
    final notesController = TextEditingController(text: workout.notes);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Edit Workout',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Workout Name',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              style: const TextStyle(color: AppColors.textPrimary),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final repo = ref.read(workoutRepositoryProvider);
        final updatedWorkout = workout.copyWith(
          name: nameController.text.isEmpty ? null : nameController.text,
          notes: notesController.text.isEmpty ? null : notesController.text,
        );
        await repo.updateWorkoutSession(updatedWorkout);

        if (!mounted) return;

        // Refresh the list
        ref.invalidate(workoutSessionsByDateProvider(_selectedDay!));
        ref.invalidate(workoutSessionsGroupedProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout updated'),
            backgroundColor: AppColors.success,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating workout: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    nameController.dispose();
    notesController.dispose();
  }

  void _deleteWorkout(WorkoutSession workout) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete Workout?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete this workout? This action cannot be undone.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repo = ref.read(workoutRepositoryProvider);
        await repo.deleteWorkoutSession(workout.id!);

        if (!mounted) return;

        // Refresh the list
        ref.invalidate(workoutSessionsByDateProvider(_selectedDay!));
        ref.invalidate(workoutSessionsGroupedProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout deleted'),
            backgroundColor: AppColors.success,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting workout: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get workouts for the current month
    final startOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final endOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0, 23, 59, 59);

    final dateRange = DateRange(startDate: startOfMonth, endDate: endOfMonth);
    final workoutsGrouped = ref.watch(workoutSessionsGroupedProvider(dateRange));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
        children: [
          // Calendar
          workoutsGrouped.when(
            data: (groupedWorkouts) => _buildCalendar(groupedWorkouts),
            loading: () => _buildCalendarLoading(),
            error: (error, stack) => _buildCalendarError(error),
          ),
          const Divider(color: AppColors.surfaceHighlight, height: 1),
          // Selected day workouts
          Expanded(
            child: _selectedDay == null
                ? _buildNoDateSelected()
                : _buildWorkoutsForDay(_selectedDay!),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildCalendar(Map<DateTime, List<WorkoutSession>> groupedWorkouts) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TableCalendar<WorkoutSession>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        calendarFormat: _calendarFormat,
        eventLoader: (day) {
          final normalizedDay = DateTime(day.year, day.month, day.day);
          return groupedWorkouts[normalizedDay] ?? [];
        },
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        calendarStyle: CalendarStyle(
          // Today
          todayDecoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          // Selected day
          selectedDecoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          // Default days
          defaultTextStyle: const TextStyle(color: AppColors.textPrimary),
          weekendTextStyle: const TextStyle(color: AppColors.textPrimary),
          // Outside days
          outsideTextStyle: const TextStyle(color: AppColors.textMuted),
          // Markers (workout indicators)
          markerDecoration: const BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
          ),
          markersMaxCount: 1,
          markerSize: 7,
          markerMargin: const EdgeInsets.symmetric(horizontal: 1),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          leftChevronIcon: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
          rightChevronIcon: const Icon(Icons.chevron_right, color: AppColors.textPrimary),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
          weekendStyle: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildCalendarLoading() {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 350,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }

  Widget _buildCalendarError(Object error) {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 350,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error loading calendar',
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDateSelected() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          const Text(
            'Select a date',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap on a date to view workouts',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutsForDay(DateTime date) {
    final workoutsAsync = ref.watch(workoutSessionsByDateProvider(date));

    return workoutsAsync.when(
      data: (workouts) {
        if (workouts.isEmpty) {
          return _buildNoWorkouts(date);
        }
        return _buildWorkoutsList(workouts, date);
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Error loading workouts',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoWorkouts(DateTime date) {
    final dateStr = DateFormat('EEEE, MMMM d').format(date);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center, size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(
            'No workouts on $dateStr',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Rest day or select another date',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutsList(List<WorkoutSession> workouts, DateTime date) {
    final dateStr = DateFormat('EEEE, MMMM d').format(date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            dateStr,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: workouts.length,
            itemBuilder: (context, index) {
              return _buildWorkoutCard(workouts[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWorkoutCard(WorkoutSession workout) {
    final startTime = DateFormat('h:mm a').format(workout.startedAt);
    final duration = workout.durationMinutes ?? 0;
    final volume = workout.totalVolume?.toStringAsFixed(0) ?? '0';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceHighlight, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            context.push('/workout-detail/${workout.id}');
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.fitness_center, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          workout.name ?? 'Workout',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          startTime,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: AppColors.textMuted, size: 20),
                          color: AppColors.surfaceElevated,
                          onSelected: (value) {
                            if (value == 'delete') {
                              _deleteWorkout(workout);
                            } else if (value == 'edit') {
                              _editWorkout(workout);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, color: AppColors.textPrimary, size: 20),
                                  SizedBox(width: 8),
                                  Text('Edit', style: TextStyle(color: AppColors.textPrimary)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: AppColors.error)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStat(Icons.timer_outlined, '$duration min', AppColors.info),
                    const SizedBox(width: 24),
                    _buildStat(Icons.fitness_center, '$volume kg', AppColors.success),
                  ],
                ),
                const SizedBox(height: 12),
                _MuscleGroupChips(workoutId: workout.id!),
                if (workout.notes != null && workout.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    workout.notes!,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// Widget to display muscle groups as chips
class _MuscleGroupChips extends ConsumerWidget {
  final int workoutId;

  const _MuscleGroupChips({required this.workoutId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muscleGroupsAsync = ref.watch(muscleGroupsForSessionProvider(workoutId));

    return muscleGroupsAsync.when(
      data: (muscleGroups) {
        if (muscleGroups.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 28,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: muscleGroups.length,
            itemBuilder: (context, index) {
              final muscleGroup = muscleGroups[index];
              final color = _getMuscleGroupColor(muscleGroup);

              return Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.3), width: 1),
                ),
                child: Text(
                  _formatMuscleGroupName(muscleGroup),
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Color _getMuscleGroupColor(String muscleGroup) {
    final colors = {
      'chest': const Color(0xFFFF6B6B),
      'back': const Color(0xFF4ECDC4),
      'shoulders': const Color(0xFF45B7D1),
      'biceps': const Color(0xFF96CEB4),
      'triceps': const Color(0xFFFFEAA7),
      'forearms': const Color(0xFFDDA0DD),
      'quads': const Color(0xFF98D8C8),
      'hamstrings': const Color(0xFFF7DC6F),
      'glutes': const Color(0xFFBB8FCE),
      'calves': const Color(0xFF85C1E9),
      'abs': const Color(0xFFF8B500),
      'obliques': const Color(0xFFF8B500),
      'lowerBack': const Color(0xFF58D68D),
      'traps': const Color(0xFF5DADE2),
      'lats': const Color(0xFF48C9B0),
      'fullBody': const Color(0xFFAF7AC5),
      'cardio': const Color(0xFFEC7063),
    };

    return colors[muscleGroup] ?? AppColors.primary;
  }

  String _formatMuscleGroupName(String muscleGroup) {
    final formatted = {
      'lowerBack': 'Lower Back',
      'fullBody': 'Full Body',
    };

    return formatted[muscleGroup] ?? muscleGroup[0].toUpperCase() + muscleGroup.substring(1);
  }
}
