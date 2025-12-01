import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../core/theme/colors.dart';
import '../../models/scheduled_workout.dart';
import '../../models/rest_day.dart';
import '../../models/workout_template.dart';
import '../../repositories/scheduled_workout_repository.dart';
import '../../repositories/rest_day_repository.dart';
import '../../repositories/template_repository.dart';

class WorkoutCalendarScreen extends StatefulWidget {
  const WorkoutCalendarScreen({super.key});

  @override
  State<WorkoutCalendarScreen> createState() => _WorkoutCalendarScreenState();
}

class _WorkoutCalendarScreenState extends State<WorkoutCalendarScreen> {
  final ScheduledWorkoutRepository _scheduledRepo = ScheduledWorkoutRepository();
  final RestDayRepository _restDayRepo = RestDayRepository();
  final TemplateRepository _templateRepo = TemplateRepository();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<ScheduledWorkout>> _scheduledWorkouts = {};
  Map<DateTime, RestDay> _restDays = {};
  List<WorkoutTemplate> _templates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final startOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final endOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

      final scheduled = await _scheduledRepo.getScheduledWorkoutsByDateRange(
        startOfMonth,
        endOfMonth,
      );
      final restDays = await _restDayRepo.getRestDaysByDateRange(
        startOfMonth,
        endOfMonth,
      );
      final templates = await _templateRepo.getAllTemplates();

      setState(() {
        _scheduledWorkouts = _groupScheduledByDate(scheduled);
        _restDays = {for (var day in restDays) day.dateOnly: day};
        _templates = templates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Map<DateTime, List<ScheduledWorkout>> _groupScheduledByDate(
    List<ScheduledWorkout> workouts,
  ) {
    final Map<DateTime, List<ScheduledWorkout>> grouped = {};
    for (final workout in workouts) {
      final date = workout.dateOnly;
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(workout);
    }
    return grouped;
  }

  List<ScheduledWorkout> _getWorkoutsForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _scheduledWorkouts[date] ?? [];
  }

  bool _isRestDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _restDays.containsKey(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Workout Calendar'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
            },
            tooltip: 'Today',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                _buildCalendar(),
                const Divider(height: 1),
                Expanded(child: _buildDayDetails()),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddOptions,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      color: AppColors.surface,
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        calendarFormat: CalendarFormat.month,
        startingDayOfWeek: StartingDayOfWeek.monday,
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          markerDecoration: const BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
          ),
          markersMaxCount: 1,
          defaultTextStyle: const TextStyle(color: AppColors.textPrimary),
          weekendTextStyle: const TextStyle(color: AppColors.textSecondary),
          outsideTextStyle: const TextStyle(color: AppColors.textMuted),
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
          weekdayStyle: TextStyle(color: AppColors.textSecondary),
          weekendStyle: TextStyle(color: AppColors.textSecondary),
        ),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onPageChanged: (focusedDay) {
          setState(() {
            _focusedDay = focusedDay;
          });
          _loadData();
        },
        eventLoader: (day) {
          final workouts = _getWorkoutsForDay(day);
          if (workouts.isNotEmpty || _isRestDay(day)) {
            return ['event'];
          }
          return [];
        },
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            if (_isRestDay(date)) {
              return Positioned(
                bottom: 1,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.warning,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            } else if (events.isNotEmpty) {
              return Positioned(
                bottom: 1,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildDayDetails() {
    if (_selectedDay == null) {
      return const Center(
        child: Text(
          'Select a day to view details',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    final workouts = _getWorkoutsForDay(_selectedDay!);
    final isRest = _isRestDay(_selectedDay!);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEEE, MMMM d, y').format(_selectedDay!),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (isRest) _buildRestDayCard(),
          if (workouts.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...workouts.map((workout) => _buildWorkoutCard(workout)),
          ],
          if (!isRest && workouts.isEmpty) _buildEmptyDayMessage(),
        ],
      ),
    );
  }

  Widget _buildRestDayCard() {
    final restDay = _restDays[DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning, width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.hotel, color: AppColors.warning, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rest Day',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (restDay?.notes != null)
                  Text(
                    restDay!.notes!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () => _deleteRestDay(restDay!.id!),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutCard(ScheduledWorkout workout) {
    final template = _templates.firstWhere(
      (t) => t.id == workout.templateId,
      orElse: () => WorkoutTemplate(name: 'Unknown', exercises: []),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: workout.completed ? AppColors.success.withOpacity(0.1) : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: workout.completed ? AppColors.success : AppColors.surfaceHighlight,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            workout.completed ? Icons.check_circle : Icons.fitness_center,
            color: workout.completed ? AppColors.success : AppColors.primary,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (template.exercises.isNotEmpty)
                  Text(
                    '${template.exercises.length} exercises',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                if (workout.notes != null)
                  Text(
                    workout.notes!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () => _deleteScheduledWorkout(workout.id!),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDayMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.calendar_today, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 16),
            const Text(
              'Nothing scheduled for this day',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.fitness_center, color: AppColors.primary),
              title: const Text('Schedule Workout', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _showScheduleWorkoutDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.hotel, color: AppColors.warning),
              title: const Text('Mark Rest Day', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _addRestDay();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showScheduleWorkoutDialog() {
    WorkoutTemplate? selectedTemplate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Schedule Workout', style: TextStyle(color: AppColors.textPrimary)),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<WorkoutTemplate>(
                  value: selectedTemplate,
                  decoration: InputDecoration(
                    labelText: 'Select Template',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: AppColors.textPrimary),
                  items: _templates.map((template) {
                    return DropdownMenuItem(
                      value: template,
                      child: Text(template.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedTemplate = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () async {
                if (selectedTemplate != null && _selectedDay != null) {
                  await _scheduleWorkout(selectedTemplate!, _selectedDay!);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('Schedule', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scheduleWorkout(WorkoutTemplate template, DateTime date) async {
    final scheduled = ScheduledWorkout(
      templateId: template.id,
      scheduledDate: date,
    );

    try {
      await _scheduledRepo.createScheduledWorkout(scheduled);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout scheduled successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scheduling workout: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _addRestDay() async {
    if (_selectedDay == null) return;

    final restDay = RestDay(restDate: _selectedDay!);

    try {
      await _restDayRepo.createRestDay(restDay);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rest day marked'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking rest day: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteScheduledWorkout(int id) async {
    try {
      await _scheduledRepo.deleteScheduledWorkout(id);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scheduled workout deleted'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting workout: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteRestDay(int id) async {
    try {
      await _restDayRepo.deleteRestDay(id);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rest day removed'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing rest day: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
