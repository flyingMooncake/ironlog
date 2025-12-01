import 'package:flutter/material.dart';
import '../core/theme/colors.dart';

class PlateCalculator extends StatefulWidget {
  final double? initialWeight;

  const PlateCalculator({super.key, this.initialWeight});

  @override
  State<PlateCalculator> createState() => _PlateCalculatorState();
}

class _PlateCalculatorState extends State<PlateCalculator> {
  final TextEditingController _weightController = TextEditingController();
  double _barWeight = 20.0; // Standard Olympic barbell
  List<PlateLoad> _plates = [];

  final List<double> _availablePlates = [25, 20, 15, 10, 5, 2.5, 1.25, 0.5];

  @override
  void initState() {
    super.initState();
    if (widget.initialWeight != null) {
      _weightController.text = widget.initialWeight!.toStringAsFixed(1);
      _calculatePlates();
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  void _calculatePlates() {
    final targetWeight = double.tryParse(_weightController.text) ?? 0;
    if (targetWeight <= _barWeight) {
      setState(() => _plates = []);
      return;
    }

    // Weight to load on each side
    double weightPerSide = (targetWeight - _barWeight) / 2;

    final plates = <PlateLoad>[];
    for (final plate in _availablePlates) {
      int count = (weightPerSide / plate).floor();
      if (count > 0) {
        plates.add(PlateLoad(weight: plate, count: count));
        weightPerSide -= plate * count;
      }
    }

    setState(() => _plates = plates);
  }

  @override
  Widget build(BuildContext context) {
    final totalWeight = _barWeight + (_plates.fold<double>(0, (sum, p) => sum + (p.weight * p.count * 2)));

    return Dialog(
      backgroundColor: AppColors.surface,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Plate Calculator',
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
            const SizedBox(height: 24),

            // Bar weight selector
            Row(
              children: [
                const Text(
                  'Bar Weight:',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(width: 12),
                ...[ 15.0, 20.0].map((weight) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('${weight.toInt()}kg'),
                    selected: _barWeight == weight,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _barWeight = weight);
                        _calculatePlates();
                      }
                    },
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surfaceElevated,
                    labelStyle: TextStyle(
                      color: _barWeight == weight ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )),
              ],
            ),
            const SizedBox(height: 16),

            // Target weight input
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
              decoration: InputDecoration(
                labelText: 'Target Weight (kg)',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                suffixIcon: IconButton(
                  onPressed: _calculatePlates,
                  icon: const Icon(Icons.calculate, color: AppColors.primary),
                ),
                filled: true,
                fillColor: AppColors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => _calculatePlates(),
            ),
            const SizedBox(height: 24),

            if (_plates.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Load Per Side',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${totalWeight.toStringAsFixed(1)} kg total',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._plates.map((plate) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _getPlateColor(plate.weight),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '${plate.weight}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${plate.count}x ${plate.weight}kg plates',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildVisualBar(),
            ] else if (_weightController.text.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'Bar only',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
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

  Widget _buildVisualBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            'Visual Guide',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Left plates
              ..._plates.map((plate) => Container(
                width: plate.weight * 1.2,
                height: 60,
                margin: const EdgeInsets.only(right: 2),
                decoration: BoxDecoration(
                  color: _getPlateColor(plate.weight),
                  borderRadius: BorderRadius.circular(4),
                ),
              )),
              // Bar
              Container(
                width: 60,
                height: 20,
                color: AppColors.textMuted,
                child: Center(
                  child: Text(
                    '${_barWeight.toInt()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Right plates (mirrored)
              ..._plates.reversed.map((plate) => Container(
                width: plate.weight * 1.2,
                height: 60,
                margin: const EdgeInsets.only(left: 2),
                decoration: BoxDecoration(
                  color: _getPlateColor(plate.weight),
                  borderRadius: BorderRadius.circular(4),
                ),
              )),
            ],
          ),
        ],
      ),
    );
  }

  Color _getPlateColor(double weight) {
    if (weight >= 25) return const Color(0xFFE53935); // Red
    if (weight >= 20) return const Color(0xFF1E88E5); // Blue
    if (weight >= 15) return const Color(0xFFFDD835); // Yellow
    if (weight >= 10) return const Color(0xFF43A047); // Green
    if (weight >= 5) return const Color(0xFF757575); // Gray
    return const Color(0xFFBDBDBD); // Light gray
  }
}

class PlateLoad {
  final double weight;
  final int count;

  PlateLoad({required this.weight, required this.count});
}
