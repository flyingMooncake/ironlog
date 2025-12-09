import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/theme/colors.dart';
import '../../models/workout_template.dart';
import '../../repositories/workout_repository.dart';
import '../../repositories/set_repository.dart';

class TemplateAnalysisScreen extends StatefulWidget {
  final WorkoutTemplate template;

  const TemplateAnalysisScreen({super.key, required this.template});

  @override
  State<TemplateAnalysisScreen> createState() => _TemplateAnalysisScreenState();
}

class _TemplateAnalysisScreenState extends State<TemplateAnalysisScreen> {
  final WorkoutRepository _workoutRepo = WorkoutRepository();
  final SetRepository _setRepo = SetRepository();

  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    if (widget.template.id == null) {
      setState(() => _isLoading = false);
      return;
    }

    // Get all workouts from this template
    final sessions = await _workoutRepo.getWorkoutSessionsByTemplateId(widget.template.id!);

    if (sessions.isEmpty) {
      setState(() {
        _stats = {'sessions': sessions};
        _isLoading = false;
      });
      return;
    }

    // Get all sets from these sessions
    double totalVolume = 0;
    int totalSets = 0;
    int totalReps = 0;
    Map<DateTime, double> volumeByDate = {};
    Map<DateTime, int> durationByDate = {};
    double totalDuration = 0;
    int sessionsWithDuration = 0;

    for (final session in sessions) {
      if (session.id != null) {
        final sets = await _setRepo.getSetsBySessionId(session.id!);

        for (final set in sets) {
          if (!set.isWarmup && set.weight != null && set.reps != null) {
            final volume = set.weight! * set.reps!;
            totalVolume += volume;
            totalSets++;
            totalReps += set.reps!;

            // Group by date
            final date = DateTime(
              session.startedAt.year,
              session.startedAt.month,
              session.startedAt.day,
            );
            volumeByDate[date] = (volumeByDate[date] ?? 0) + volume;
          }
        }

        // Track duration
        if (session.durationMinutes != null) {
          final date = DateTime(
            session.startedAt.year,
            session.startedAt.month,
            session.startedAt.day,
          );
          durationByDate[date] = session.durationMinutes!;
          totalDuration += session.durationMinutes!;
          sessionsWithDuration++;
        }
      }
    }

    setState(() {
      _stats = {
        'sessions': sessions,
        'totalVolume': totalVolume,
        'totalSets': totalSets,
        'totalReps': totalReps,
        'volumeByDate': volumeByDate,
        'durationByDate': durationByDate,
        'avgVolume': sessions.isNotEmpty ? totalVolume / sessions.length : 0,
        'avgSets': sessions.isNotEmpty ? totalSets / sessions.length : 0,
        'avgDuration': sessionsWithDuration > 0 ? totalDuration / sessionsWithDuration : 0,
      };
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.template.name),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _stats['sessions']?.isEmpty ?? true
              ? _buildEmptyState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildStatsOverview(),
                      const SizedBox(height: 24),
                      _buildVolumeChart(),
                      const SizedBox(height: 24),
                      _buildWorkoutHistory(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.analytics_outlined,
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          const Text(
            'No workouts yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start a workout from this template to see analytics',
            style: TextStyle(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.analytics,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Template Analysis',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_stats['sessions']?.length ?? 0} workouts completed',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview() {
    final totalVolume = _stats['totalVolume'] ?? 0.0;
    final avgVolume = _stats['avgVolume'] ?? 0.0;
    final avgSets = _stats['avgSets'] ?? 0.0;
    final avgDuration = _stats['avgDuration'] ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                label: 'Total Volume',
                value: '${(totalVolume / 1000).toStringAsFixed(1)}k kg',
                icon: Icons.fitness_center,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                label: 'Avg Volume',
                value: '${avgVolume.toStringAsFixed(0)} kg',
                icon: Icons.trending_up,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                label: 'Avg Sets',
                value: avgSets.toStringAsFixed(0),
                icon: Icons.grid_on,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                label: 'Avg Duration',
                value: '${avgDuration.toStringAsFixed(0)} min',
                icon: Icons.access_time,
                color: AppColors.info,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeChart() {
    final volumeByDate = _stats['volumeByDate'] as Map<DateTime, double>? ?? {};

    if (volumeByDate.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedDates = volumeByDate.keys.toList()..sort();
    final maxVolume = volumeByDate.values.reduce((a, b) => a > b ? a : b);

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
            'Volume Progression',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxVolume / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.surfaceHighlight,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${(value / 1000).toStringAsFixed(0)}k',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value < 0 || value >= sortedDates.length) {
                          return const SizedBox.shrink();
                        }
                        final date = sortedDates[value.toInt()];
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
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (sortedDates.length - 1).toDouble(),
                minY: 0,
                maxY: maxVolume * 1.2,
                lineBarsData: [
                  LineChartBarData(
                    spots: sortedDates.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        volumeByDate[entry.value]!,
                      );
                    }).toList(),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutHistory() {
    final sessions = _stats['sessions'] as List? ?? [];

    if (sessions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Workouts',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...sessions.take(10).map((session) => _buildWorkoutCard(session)),
      ],
    );
  }

  Widget _buildWorkoutCard(dynamic session) {
    final date = DateFormat('MMM d, yyyy').format(session.startedAt);
    final volume = session.totalVolume?.toStringAsFixed(0) ?? '0';
    final duration = session.durationMinutes?.toString() ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$volume kg • $duration min',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: AppColors.textMuted,
            size: 20,
          ),
        ],
      ),
    );
  }
}
