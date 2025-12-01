import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/theme/colors.dart';
import '../../providers/stats_provider.dart';
import '../../providers/workout_provider.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  DateTime _selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Progress'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Volume over time chart
            _buildSectionHeader('Volume Over Time'),
            const SizedBox(height: 16),
            _buildVolumeChart(),
            const SizedBox(height: 32),

            // Workout calendar
            _buildSectionHeader('Workout Calendar'),
            const SizedBox(height: 16),
            _buildWorkoutCalendar(),
            const SizedBox(height: 32),

            // Muscle group breakdown
            _buildSectionHeader('Muscle Group Volume (Last 30 Days)'),
            const SizedBox(height: 16),
            _buildMuscleGroupBreakdown(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildVolumeChart() {
    final volumeDataAsync = ref.watch(volumeOverTimeProvider);

    return volumeDataAsync.when(
      data: (volumeData) {
        if (volumeData.isEmpty) {
          return _buildEmptyChartState('No workout data yet');
        }

        // Take last 30 data points
        final displayData = volumeData.length > 30
            ? volumeData.sublist(volumeData.length - 30)
            : volumeData;

        return Container(
          height: 250,
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
                    interval: (displayData.length / 5).ceilToDouble(),
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < displayData.length) {
                        final date = displayData[value.toInt()].date;
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
                        '${(value / 1000).toStringAsFixed(0)}k',
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
              maxX: (displayData.length - 1).toDouble(),
              minY: 0,
              maxY: _getMaxVolume(displayData) * 1.1,
              lineBarsData: [
                LineChartBarData(
                  spots: displayData.asMap().entries.map((entry) {
                    return FlSpot(entry.key.toDouble(), entry.value.volume);
                  }).toList(),
                  isCurved: true,
                  color: AppColors.primary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 3,
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
      },
      loading: () => _buildLoadingChartState(),
      error: (error, stack) => _buildEmptyChartState('Error loading data'),
    );
  }

  double _getMaxVolume(List<VolumeData> data) {
    if (data.isEmpty) return 1000;
    return data.map((e) => e.volume).reduce((a, b) => a > b ? a : b);
  }

  Widget _buildWorkoutCalendar() {
    final workoutsAsync = ref.watch(allWorkoutSessionsProvider);

    return workoutsAsync.when(
      data: (workouts) {
        final workoutDates = workouts.map((w) => DateTime(
          w.startedAt.year,
          w.startedAt.month,
          w.startedAt.day,
        )).toSet();

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now(),
            focusedDay: _selectedMonth,
            calendarFormat: CalendarFormat.month,
            onPageChanged: (focusedDay) {
              setState(() {
                _selectedMonth = focusedDay;
              });
            },
            calendarStyle: CalendarStyle(
              defaultTextStyle: const TextStyle(color: AppColors.textPrimary),
              weekendTextStyle: const TextStyle(color: AppColors.textSecondary),
              outsideTextStyle: const TextStyle(color: AppColors.textMuted),
              todayDecoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              titleTextStyle: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              formatButtonVisible: false,
              leftChevronIcon: const Icon(Icons.chevron_left, color: AppColors.primary),
              rightChevronIcon: const Icon(Icons.chevron_right, color: AppColors.primary),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              weekendStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                final hasWorkout = workoutDates.contains(DateTime(day.year, day.month, day.day));
                return Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: hasWorkout ? AppColors.success.withOpacity(0.2) : null,
                    shape: BoxShape.circle,
                    border: hasWorkout ? Border.all(color: AppColors.success, width: 2) : null,
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: hasWorkout ? AppColors.success : AppColors.textPrimary,
                        fontWeight: hasWorkout ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
              todayBuilder: (context, day, focusedDay) {
                final hasWorkout = workoutDates.contains(DateTime(day.year, day.month, day.day));
                return Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: hasWorkout
                        ? AppColors.success.withOpacity(0.3)
                        : AppColors.info.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: hasWorkout ? AppColors.success : AppColors.info,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: hasWorkout ? AppColors.success : AppColors.info,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
      loading: () => _buildLoadingChartState(),
      error: (error, stack) => _buildEmptyChartState('Error loading calendar'),
    );
  }

  Widget _buildMuscleGroupBreakdown() {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final dateRange = StatsDateRange(start: thirtyDaysAgo, end: now);

    final muscleVolumeAsync = ref.watch(muscleGroupVolumeProvider(dateRange));

    return muscleVolumeAsync.when(
      data: (muscleVolumes) {
        if (muscleVolumes.isEmpty) {
          return _buildEmptyChartState('No workout data in the last 30 days');
        }

        final sortedEntries = muscleVolumes.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: sortedEntries.map((entry) {
              final muscle = entry.key;
              final volume = entry.value;
              final maxVolume = sortedEntries.first.value;
              final percentage = (volume / maxVolume * 100).toInt();

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          muscle[0].toUpperCase() + muscle.substring(1),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${(volume / 1000).toStringAsFixed(1)}k kg',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: volume / maxVolume,
                        backgroundColor: AppColors.surfaceElevated,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getMuscleColor(muscle),
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
      loading: () => _buildLoadingChartState(),
      error: (error, stack) => _buildEmptyChartState('Error loading muscle data'),
    );
  }

  Color _getMuscleColor(String muscle) {
    final colors = AppColors.muscleColors;
    return colors[muscle] ?? AppColors.primary;
  }

  Widget _buildEmptyChartState(String message) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingChartState() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}
