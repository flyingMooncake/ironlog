import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/colors.dart';
import '../../models/body_measurement.dart';
import '../../repositories/body_measurement_repository.dart';

class BodyMeasurementsScreen extends StatefulWidget {
  const BodyMeasurementsScreen({super.key});

  @override
  State<BodyMeasurementsScreen> createState() => _BodyMeasurementsScreenState();
}

class _BodyMeasurementsScreenState extends State<BodyMeasurementsScreen> {
  final BodyMeasurementRepository _repo = BodyMeasurementRepository();
  List<BodyMeasurement> _measurements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMeasurements();
  }

  Future<void> _loadMeasurements() async {
    setState(() => _isLoading = true);
    final measurements = await _repo.getAllMeasurements();
    setState(() {
      _measurements = measurements;
      _isLoading = false;
    });
  }

  void _showAddMeasurementDialog() {
    final controllers = {
      'chest': TextEditingController(),
      'waist': TextEditingController(),
      'hips': TextEditingController(),
      'leftArm': TextEditingController(),
      'rightArm': TextEditingController(),
      'leftThigh': TextEditingController(),
      'rightThigh': TextEditingController(),
      'leftCalf': TextEditingController(),
      'rightCalf': TextEditingController(),
      'shoulders': TextEditingController(),
      'neck': TextEditingController(),
      'notes': TextEditingController(),
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Add Body Measurements',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMeasurementField('Chest', controllers['chest']!),
              _buildMeasurementField('Waist', controllers['waist']!),
              _buildMeasurementField('Hips', controllers['hips']!),
              _buildMeasurementField('Left Arm', controllers['leftArm']!),
              _buildMeasurementField('Right Arm', controllers['rightArm']!),
              _buildMeasurementField('Left Thigh', controllers['leftThigh']!),
              _buildMeasurementField('Right Thigh', controllers['rightThigh']!),
              _buildMeasurementField('Left Calf', controllers['leftCalf']!),
              _buildMeasurementField('Right Calf', controllers['rightCalf']!),
              _buildMeasurementField('Shoulders', controllers['shoulders']!),
              _buildMeasurementField('Neck', controllers['neck']!),
              const SizedBox(height: 8),
              TextField(
                controller: controllers['notes']!,
                maxLines: 3,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Notes (optional)',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
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
              final measurement = BodyMeasurement(
                chest: double.tryParse(controllers['chest']!.text),
                waist: double.tryParse(controllers['waist']!.text),
                hips: double.tryParse(controllers['hips']!.text),
                leftArm: double.tryParse(controllers['leftArm']!.text),
                rightArm: double.tryParse(controllers['rightArm']!.text),
                leftThigh: double.tryParse(controllers['leftThigh']!.text),
                rightThigh: double.tryParse(controllers['rightThigh']!.text),
                leftCalf: double.tryParse(controllers['leftCalf']!.text),
                rightCalf: double.tryParse(controllers['rightCalf']!.text),
                shoulders: double.tryParse(controllers['shoulders']!.text),
                neck: double.tryParse(controllers['neck']!.text),
                notes: controllers['notes']!.text.isEmpty ? null : controllers['notes']!.text,
              );

              await _repo.saveMeasurement(measurement);
              _loadMeasurements();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    ).then((_) {
      // Clean up controllers after dialog is closed
      for (final controller in controllers.values) {
        controller.dispose();
      }
    });
  }

  void _deleteMeasurement(BodyMeasurement measurement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete Measurement',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete the measurement from ${DateFormat('MMM d, y').format(measurement.recordedAt)}?',
          style: const TextStyle(color: AppColors.textSecondary),
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

    if (confirmed == true && measurement.id != null) {
      await _repo.deleteMeasurement(measurement.id!);
      _loadMeasurements();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Measurement deleted'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Widget _buildMeasurementField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: '$label (cm)',
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          filled: true,
          fillColor: AppColors.surfaceElevated,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Body Measurements'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMeasurementDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Add Measurement'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _measurements.isEmpty
              ? _buildEmptyState()
              : _buildMeasurementsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.straighten,
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          const Text(
            'No measurements yet',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Track your body measurements over time',
            style: TextStyle(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _measurements.length,
      itemBuilder: (context, index) {
        final measurement = _measurements[index];
        return _buildMeasurementCard(measurement);
      },
    );
  }

  Widget _buildMeasurementCard(BodyMeasurement measurement) {
    final hasComparison = _measurements.length > 1;
    BodyMeasurement? previous;
    if (hasComparison) {
      final currentIndex = _measurements.indexOf(measurement);
      if (currentIndex < _measurements.length - 1) {
        previous = _measurements[currentIndex + 1];
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    DateFormat('MMM d, y').format(measurement.recordedAt),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _deleteMeasurement(measurement),
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  tooltip: 'Delete',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.surfaceHighlight, height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (measurement.chest != null)
                  _buildMeasurementRow('Chest', measurement.chest!, previous?.chest),
                if (measurement.waist != null)
                  _buildMeasurementRow('Waist', measurement.waist!, previous?.waist),
                if (measurement.hips != null)
                  _buildMeasurementRow('Hips', measurement.hips!, previous?.hips),
                if (measurement.shoulders != null)
                  _buildMeasurementRow('Shoulders', measurement.shoulders!, previous?.shoulders),
                if (measurement.neck != null)
                  _buildMeasurementRow('Neck', measurement.neck!, previous?.neck),
                if (measurement.leftArm != null)
                  _buildMeasurementRow('Left Arm', measurement.leftArm!, previous?.leftArm),
                if (measurement.rightArm != null)
                  _buildMeasurementRow('Right Arm', measurement.rightArm!, previous?.rightArm),
                if (measurement.leftThigh != null)
                  _buildMeasurementRow('Left Thigh', measurement.leftThigh!, previous?.leftThigh),
                if (measurement.rightThigh != null)
                  _buildMeasurementRow('Right Thigh', measurement.rightThigh!, previous?.rightThigh),
                if (measurement.leftCalf != null)
                  _buildMeasurementRow('Left Calf', measurement.leftCalf!, previous?.leftCalf),
                if (measurement.rightCalf != null)
                  _buildMeasurementRow('Right Calf', measurement.rightCalf!, previous?.rightCalf),
              ],
            ),
          ),
          if (measurement.notes != null) ...[
            const Divider(color: AppColors.surfaceHighlight, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notes',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    measurement.notes!,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMeasurementRow(String label, double value, double? previous) {
    final diff = previous != null ? value - previous : null;
    final hasDiff = diff != null && diff != 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          Row(
            children: [
              Text(
                '${value.toStringAsFixed(1)} cm',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (hasDiff) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: diff! > 0
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${diff > 0 ? '+' : ''}${diff.toStringAsFixed(1)}',
                    style: TextStyle(
                      color: diff > 0 ? AppColors.success : AppColors.error,
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
    );
  }
}
