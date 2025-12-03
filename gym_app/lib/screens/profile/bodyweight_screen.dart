import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/theme/colors.dart';
import '../../models/weight_entry.dart';
import '../../providers/weight_history_provider.dart';
import '../../repositories/weight_history_repository.dart';

class BodyweightScreen extends ConsumerStatefulWidget {
  const BodyweightScreen({super.key});

  @override
  ConsumerState<BodyweightScreen> createState() => _BodyweightScreenState();
}

class _BodyweightScreenState extends ConsumerState<BodyweightScreen> {
  String _selectedPeriod = '3M'; // 1M, 3M, 6M, 1Y, All

  @override
  Widget build(BuildContext context) {
    final weightEntriesAsync = ref.watch(allWeightEntriesProvider);
    final latestWeightAsync = ref.watch(latestWeightEntryProvider);
    final weightChange30d = ref.watch(weightChangeProvider(30));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bodyweight Tracking'),
        elevation: 0,
      ),
      body: weightEntriesAsync.when(
        data: (entries) {
          final filteredEntries = _filterEntriesByPeriod(entries);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsCards(latestWeightAsync, weightChange30d),
                const SizedBox(height: 24),
                _buildPeriodSelector(),
                const SizedBox(height: 16),
                _buildWeightChart(filteredEntries),
                const SizedBox(height: 24),
                _buildEntriesList(entries),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stack) => Center(
          child: Text(
            'Error loading weight history',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddWeightDialog(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Add Weight'),
      ),
    );
  }

  Widget _buildStatsCards(
    AsyncValue<WeightEntry?> latestWeightAsync,
    AsyncValue<Map<String, double>> weightChange30d,
  ) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Weight',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                latestWeightAsync.when(
                  data: (entry) => Text(
                    entry != null ? '${entry.weight.toStringAsFixed(1)} kg' : 'N/A',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  loading: () => const Text('...', style: TextStyle(fontSize: 28)),
                  error: (_, __) => const Text('N/A', style: TextStyle(fontSize: 28)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '30-Day Change',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                weightChange30d.when(
                  data: (change) {
                    final changeValue = change['change'] ?? 0;
                    final isPositive = changeValue > 0;
                    final isNegative = changeValue < 0;

                    return Row(
                      children: [
                        if (isPositive)
                          const Icon(Icons.arrow_upward, color: AppColors.warning, size: 20)
                        else if (isNegative)
                          const Icon(Icons.arrow_downward, color: AppColors.success, size: 20)
                        else
                          const Icon(Icons.remove, color: AppColors.textMuted, size: 20),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${changeValue.abs().toStringAsFixed(1)} kg',
                            style: TextStyle(
                              color: isPositive
                                  ? AppColors.warning
                                  : isNegative
                                      ? AppColors.success
                                      : AppColors.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const Text('...', style: TextStyle(fontSize: 24)),
                  error: (_, __) => const Text('N/A', style: TextStyle(fontSize: 24)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      children: [
        const Text(
          'Period: ',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        ..._buildPeriodChips(),
      ],
    );
  }

  List<Widget> _buildPeriodChips() {
    final periods = ['1M', '3M', '6M', '1Y', 'All'];
    return periods.map((period) {
      final isSelected = _selectedPeriod == period;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(period),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedPeriod = period;
            });
          },
          selectedColor: AppColors.primary,
          backgroundColor: AppColors.surfaceElevated,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }).toList();
  }

  Widget _buildWeightChart(List<WeightEntry> entries) {
    if (entries.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'No weight data available',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    // Sort entries by date (oldest to newest)
    final sortedEntries = List<WeightEntry>.from(entries)
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    final spots = sortedEntries.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.weight);
    }).toList();

    final weights = sortedEntries.map((e) => e.weight).toList();
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);
    final padding = (maxWeight - minWeight) * 0.1;

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}kg',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
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
                interval: (sortedEntries.length / 5).ceilToDouble(),
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= sortedEntries.length) return const SizedBox();
                  final date = sortedEntries[value.toInt()].recordedAt;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('MMM d').format(date),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minY: minWeight - padding,
          maxY: maxWeight + padding,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
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

  Widget _buildEntriesList(List<WeightEntry> entries) {
    if (entries.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'History',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...entries.take(10).map((entry) => _buildEntryCard(entry)),
      ],
    );
  }

  Widget _buildEntryCard(WeightEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.monitor_weight,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.weight.toStringAsFixed(1)} kg',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  DateFormat('MMM d, yyyy - HH:mm').format(entry.recordedAt),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _deleteWeightEntry(entry),
            icon: const Icon(Icons.delete_outline, color: AppColors.textMuted, size: 20),
          ),
        ],
      ),
    );
  }

  List<WeightEntry> _filterEntriesByPeriod(List<WeightEntry> entries) {
    if (_selectedPeriod == 'All') return entries;

    final now = DateTime.now();
    final daysMap = {
      '1M': 30,
      '3M': 90,
      '6M': 180,
      '1Y': 365,
    };

    final days = daysMap[_selectedPeriod] ?? 90;
    final cutoffDate = now.subtract(Duration(days: days));

    return entries.where((entry) => entry.recordedAt.isAfter(cutoffDate)).toList();
  }

  void _showAddWeightDialog(BuildContext context) {
    final weightController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Add Weight Entry',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppColors.textPrimary),
                onChanged: (value) {
                  // Remove leading zeros except for decimal values like "0.5"
                  if (value.isNotEmpty &&
                      value.startsWith('0') &&
                      value.length > 1 &&
                      !value.startsWith('0.')) {
                    var normalized = value.replaceFirst(RegExp(r'^0+'), '');
                    if (normalized.isEmpty || normalized.startsWith('.')) {
                      normalized = '0$normalized';
                    }
                    weightController.value = TextEditingValue(
                      text: normalized,
                      selection: TextSelection.collapsed(offset: normalized.length),
                    );
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Weight (kg)',
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
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
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
                  if (date != null) {
                    setDialogState(() {
                      selectedDate = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        selectedDate.hour,
                        selectedDate.minute,
                      );
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('MMM d, yyyy').format(selectedDate),
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            TextButton(
              onPressed: () async {
                final weight = double.tryParse(weightController.text);
                if (weight == null || weight <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid weight'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                final entry = WeightEntry(
                  weight: weight,
                  recordedAt: selectedDate,
                );

                final repo = ref.read(weightHistoryRepositoryProvider);
                await repo.createWeightEntry(entry);

                ref.invalidate(allWeightEntriesProvider);
                ref.invalidate(latestWeightEntryProvider);
                ref.invalidate(weightChangeProvider);

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Weight entry added'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: const Text('Add', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    ).then((_) {
      // Clean up controller after dialog is closed
      weightController.dispose();
    });
  }

  void _deleteWeightEntry(WeightEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete Entry',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to delete this weight entry?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && entry.id != null) {
      final repo = ref.read(weightHistoryRepositoryProvider);
      await repo.deleteWeightEntry(entry.id!);

      ref.invalidate(allWeightEntriesProvider);
      ref.invalidate(latestWeightEntryProvider);
      ref.invalidate(weightChangeProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Weight entry deleted'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }
}
