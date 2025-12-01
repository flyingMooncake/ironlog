import 'package:flutter/material.dart';
import '../core/theme/colors.dart';

class OneRMCalculator extends StatefulWidget {
  final double? initialWeight;
  final int? initialReps;

  const OneRMCalculator({
    super.key,
    this.initialWeight,
    this.initialReps,
  });

  @override
  State<OneRMCalculator> createState() => _OneRMCalculatorState();
}

class _OneRMCalculatorState extends State<OneRMCalculator> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();
  double? _oneRM;
  Map<int, double> _percentages = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialWeight != null) {
      _weightController.text = widget.initialWeight!.toStringAsFixed(1);
    }
    if (widget.initialReps != null) {
      _repsController.text = widget.initialReps.toString();
    }
    if (widget.initialWeight != null && widget.initialReps != null) {
      _calculate();
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  void _calculate() {
    final weight = double.tryParse(_weightController.text);
    final reps = int.tryParse(_repsController.text);

    if (weight == null || reps == null || reps < 1) {
      setState(() {
        _oneRM = null;
        _percentages = {};
      });
      return;
    }

    // Calculate 1RM using Epley formula: 1RM = weight × (1 + reps/30)
    final oneRM = weight * (1 + reps / 30);

    // Calculate percentages for common rep ranges
    final percentages = <int, double>{
      100: oneRM,
      95: oneRM * 0.95,
      90: oneRM * 0.90,
      85: oneRM * 0.85,
      80: oneRM * 0.80,
      75: oneRM * 0.75,
      70: oneRM * 0.70,
      65: oneRM * 0.65,
      60: oneRM * 0.60,
    };

    setState(() {
      _oneRM = oneRM;
      _percentages = percentages;
    });
  }

  String _getRepRange(int percentage) {
    switch (percentage) {
      case 100:
        return '1 rep';
      case 95:
        return '2 reps';
      case 90:
        return '3-4 reps';
      case 85:
        return '5-6 reps';
      case 80:
        return '7-8 reps';
      case 75:
        return '9-10 reps';
      case 70:
        return '11-12 reps';
      case 65:
        return '13-15 reps';
      case 60:
        return '16-20 reps';
      default:
        return '';
    }
  }

  Color _getPercentageColor(int percentage) {
    if (percentage >= 90) return AppColors.error;
    if (percentage >= 80) return AppColors.warning;
    if (percentage >= 70) return AppColors.primary;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      child: Container(
        width: 400,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '1RM Calculator',
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
            const SizedBox(height: 8),
            const Text(
              'Calculate your estimated one-rep max and training percentages',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),

            // Weight input
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
              decoration: InputDecoration(
                labelText: 'Weight (kg)',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.fitness_center, color: AppColors.primary),
                filled: true,
                fillColor: AppColors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => _calculate(),
            ),
            const SizedBox(height: 16),

            // Reps input
            TextField(
              controller: _repsController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
              decoration: InputDecoration(
                labelText: 'Reps',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.repeat, color: AppColors.primary),
                filled: true,
                fillColor: AppColors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => _calculate(),
            ),
            const SizedBox(height: 24),

            if (_oneRM != null) ...[
              // 1RM Result
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Estimated 1RM',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_oneRM!.toStringAsFixed(1)} kg',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Using Epley Formula',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Training percentages
              const Text(
                'Training Percentages',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: _percentages.entries.map((entry) {
                      return _buildPercentageRow(
                        percentage: entry.key,
                        weight: entry.value,
                      );
                    }).toList(),
                  ),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.calculate,
                        size: 48,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Enter weight and reps to calculate',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPercentageRow({
    required int percentage,
    required double weight,
  }) {
    final color = _getPercentageColor(percentage);
    final repRange = _getRepRange(percentage);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '$percentage%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${weight.toStringAsFixed(1)} kg',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  repRange,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
