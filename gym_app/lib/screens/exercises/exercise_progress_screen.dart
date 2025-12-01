import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/theme/colors.dart';
import '../../models/exercise.dart';
import '../../models/exercise_target.dart';
import '../../providers/stats_provider.dart';
import '../../providers/target_provider.dart';
import '../../providers/exercise_provider.dart';
import '../../repositories/target_repository.dart';

class ExerciseProgressScreen extends ConsumerStatefulWidget {
  final Exercise exercise;

  const ExerciseProgressScreen({
    super.key,
    required this.exercise,
  });

  @override
  ConsumerState<ExerciseProgressScreen> createState() => _ExerciseProgressScreenState();
}

class _ExerciseProgressScreenState extends ConsumerState<ExerciseProgressScreen> {
  String _selectedMetric = 'weight'; // weight, reps, 1rm, volume

  @override
  Widget build(BuildContext context) {
    final progressAsync = ref.watch(exerciseProgressProvider(widget.exercise.id!));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.exercise.name),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGoalDialog(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.flag),
      ),
      body: progressAsync.when(
        data: (progressData) {
          if (progressData.isEmpty) {
            return _buildEmptyState();
          }
          return _buildContent(progressData);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stack) => Center(
          child: Text(
            'Error loading progress',
            style: const TextStyle(color: AppColors.error),
          ),
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
            Icons.trending_up,
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          const Text(
            'No progress data yet',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Complete some workouts to see your progress',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<ExerciseProgressData> progressData) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instructions section (if notes exist)
          if (widget.exercise.notes != null && widget.exercise.notes!.isNotEmpty)
            _buildInstructionsSection(),
          if (widget.exercise.notes != null && widget.exercise.notes!.isNotEmpty)
            const SizedBox(height: 24),

          // Metric selector
          _buildMetricSelector(),
          const SizedBox(height: 24),

          // Chart
          _buildChart(progressData),
          const SizedBox(height: 24),

          // Stats summary
          _buildStatsSummary(progressData),
          const SizedBox(height: 24),

          // Goals section
          _buildGoalsSection(),
          const SizedBox(height: 80), // Extra padding for FAB
        ],
      ),
    );
  }

  Widget _buildMetricSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildMetricButton('Weight', 'weight'),
          _buildMetricButton('Reps', 'reps'),
          _buildMetricButton('1RM', '1rm'),
          _buildMetricButton('Volume', 'volume'),
        ],
      ),
    );
  }

  Widget _buildMetricButton(String label, String value) {
    final isSelected = _selectedMetric == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedMetric = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChart(List<ExerciseProgressData> progressData) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppColors.surfaceHighlight,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < progressData.length) {
                    final date = progressData[value.toInt()].date;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        DateFormat('M/d').format(date),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(0),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  );
                },
                reservedSize: 40,
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (progressData.length - 1).toDouble(),
          minY: 0,
          maxY: _getMaxY(progressData) * 1.1,
          lineBarsData: [
            LineChartBarData(
              spots: _getChartSpots(progressData),
              isCurved: true,
              color: AppColors.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: AppColors.primary,
                    strokeWidth: 2,
                    strokeColor: AppColors.surface,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _getChartSpots(List<ExerciseProgressData> progressData) {
    final spots = <FlSpot>[];

    for (int i = 0; i < progressData.length; i++) {
      final data = progressData[i];
      double? yValue;

      switch (_selectedMetric) {
        case 'weight':
          yValue = data.maxWeight;
          break;
        case 'reps':
          yValue = data.maxReps?.toDouble();
          break;
        case '1rm':
          yValue = data.estimated1RM;
          break;
        case 'volume':
          yValue = data.totalVolume;
          break;
      }

      if (yValue != null && yValue > 0) {
        spots.add(FlSpot(i.toDouble(), yValue));
      }
    }

    return spots;
  }

  double _getMaxY(List<ExerciseProgressData> progressData) {
    double max = 0;

    for (final data in progressData) {
      double? value;

      switch (_selectedMetric) {
        case 'weight':
          value = data.maxWeight;
          break;
        case 'reps':
          value = data.maxReps?.toDouble();
          break;
        case '1rm':
          value = data.estimated1RM;
          break;
        case 'volume':
          value = data.totalVolume;
          break;
      }

      if (value != null && value > max) {
        max = value;
      }
    }

    return max > 0 ? max : 100;
  }

  Widget _buildStatsSummary(List<ExerciseProgressData> progressData) {
    final latest = progressData.last;
    final earliest = progressData.first;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progress Summary',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Latest Weight',
                  '${latest.maxWeight?.toStringAsFixed(1) ?? '—'} kg',
                  Icons.fitness_center,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Latest Reps',
                  '${latest.maxReps ?? '—'}',
                  Icons.repeat,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Est. 1RM',
                  '${latest.estimated1RM?.toStringAsFixed(0) ?? '—'} kg',
                  Icons.trending_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Total Workouts',
                  '${progressData.length}',
                  Icons.event,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsSection() {
    final goalsAsync = ref.watch(exerciseTargetsProvider(widget.exercise.id!));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Goals',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showAddGoalDialog(context),
              icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
              label: const Text('Add Goal', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        goalsAsync.when(
          data: (goals) {
            if (goals.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'No goals set yet. Tap + to add one!',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              );
            }

            return Column(
              children: goals.map((goal) => _buildGoalCard(goal)).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (_, __) => const Text('Error loading goals', style: TextStyle(color: AppColors.error)),
        ),
      ],
    );
  }

  Widget _buildGoalCard(ExerciseTarget goal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: goal.isAchieved
            ? Border.all(color: AppColors.success, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          goal.targetType.displayName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (goal.isAchieved)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Achieved!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (goal.isOverdue && !goal.isAchieved)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Overdue',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Target: ${goal.targetValue.toStringAsFixed(goal.targetType == TargetType.reps ? 0 : 1)} ${_getUnitForTargetType(goal.targetType)}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    if (goal.deadline != null)
                      Text(
                        'Deadline: ${DateFormat('MMM d, y').format(goal.deadline!)}',
                        style: TextStyle(
                          color: goal.isOverdue ? AppColors.error : AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _deleteGoal(goal.id!),
                icon: const Icon(Icons.delete_outline, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: goal.progressPercentage / 100,
                    backgroundColor: AppColors.surfaceElevated,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      goal.isAchieved ? AppColors.success : AppColors.primary,
                    ),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${goal.progressPercentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: goal.isAchieved ? AppColors.success : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Current: ${goal.currentValue.toStringAsFixed(goal.targetType == TargetType.reps ? 0 : 1)} ${_getUnitForTargetType(goal.targetType)}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _getUnitForTargetType(TargetType type) {
    switch (type) {
      case TargetType.weight:
        return 'kg';
      case TargetType.reps:
        return 'reps';
      case TargetType.oneRM:
        return 'kg';
      case TargetType.volume:
        return 'kg';
      case TargetType.frequency:
        return 'times/week';
    }
  }

  Widget _buildInstructionsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Form Tips & Instructions',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (widget.exercise.isCustom)
                IconButton(
                  onPressed: () => _showEditInstructionsDialog(context),
                  icon: const Icon(Icons.edit, color: AppColors.primary, size: 20),
                  tooltip: 'Edit instructions',
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.exercise.notes ?? '',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddGoalDialog(
        exerciseId: widget.exercise.id!,
        onGoalAdded: () {
          ref.invalidate(exerciseTargetsProvider(widget.exercise.id!));
        },
      ),
    );
  }

  void _deleteGoal(int goalId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Goal?', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Are you sure you want to delete this goal?',
          style: TextStyle(color: AppColors.textSecondary),
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
      final repo = ref.read(targetRepositoryProvider);
      await repo.deleteTarget(goalId);
      ref.invalidate(exerciseTargetsProvider(widget.exercise.id!));
    }
  }

  void _showEditInstructionsDialog(BuildContext context) {
    final controller = TextEditingController(text: widget.exercise.notes ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Edit Instructions',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: controller,
            maxLines: 8,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Enter form tips and instructions...',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.surfaceElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.dispose();
              Navigator.pop(context);
            },
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final updatedExercise = Exercise(
                id: widget.exercise.id,
                name: widget.exercise.name,
                primaryMuscle: widget.exercise.primaryMuscle,
                secondaryMuscles: widget.exercise.secondaryMuscles,
                trackingType: widget.exercise.trackingType,
                equipment: widget.exercise.equipment,
                isCustom: widget.exercise.isCustom,
                notes: controller.text.trim().isEmpty ? null : controller.text.trim(),
                createdAt: widget.exercise.createdAt,
              );

              final repo = ref.read(exerciseRepositoryProvider);
              await repo.updateExercise(updatedExercise);

              controller.dispose();
              if (!mounted) return;
              Navigator.pop(context);

              // Refresh the screen
              setState(() {});

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Instructions updated'),
                  backgroundColor: AppColors.success,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Save', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

// Dialog for adding a new goal
class AddGoalDialog extends StatefulWidget {
  final int exerciseId;
  final VoidCallback onGoalAdded;

  const AddGoalDialog({
    super.key,
    required this.exerciseId,
    required this.onGoalAdded,
  });

  @override
  State<AddGoalDialog> createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends State<AddGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _targetController = TextEditingController();
  TargetType _selectedType = TargetType.oneRM;
  DateTime? _deadline;

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Add Goal',
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
                const SizedBox(height: 20),
                DropdownButtonFormField<TargetType>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    labelText: 'Goal Type',
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
                  items: TargetType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _targetController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Target Value',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a target value';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Deadline (Optional)',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    _deadline != null
                        ? DateFormat('MMM d, y').format(_deadline!)
                        : 'No deadline set',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  trailing: IconButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          _deadline = date;
                        });
                      }
                    },
                    icon: const Icon(Icons.calendar_today, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveGoal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Create Goal'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _saveGoal() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final target = ExerciseTarget(
      exerciseId: widget.exerciseId,
      targetType: _selectedType,
      targetValue: double.parse(_targetController.text),
      deadline: _deadline,
    );

    try {
      final repo = TargetRepository();
      await repo.createTarget(target);

      // Update progress immediately
      await repo.updateTargetProgress(widget.exerciseId);

      if (!mounted) return;

      Navigator.pop(context);
      widget.onGoalAdded();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Goal created successfully'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating goal: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
