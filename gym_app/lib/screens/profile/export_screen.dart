import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../services/export_service.dart';
import '../../providers/workout_provider.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  final ExportService _exportService = ExportService();
  bool _isLoading = true;
  bool _isExporting = false;
  bool _isImporting = false;
  Map<String, int> _stats = {};
  int _exportSize = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _exportService.getExportStats();
      final size = await _exportService.getExportSize();
      setState(() {
        _stats = stats;
        _exportSize = size;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading export stats: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);
    try {
      await _exportService.exportAndShare();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data exported successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting data: $e'),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Export Data'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: 24),
                  _buildStatsSection(),
                  const SizedBox(height: 24),
                  _buildExportSizeCard(),
                  const SizedBox(height: 32),
                  _buildExportButton(),
                  const SizedBox(height: 16),
                  _buildImportButton(),
                ],
              ),
            ),
    );
  }

  Future<void> _importWorkout() async {
    setState(() => _isImporting = true);
    try {
      // Pick JSON file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isImporting = false);
        return;
      }

      final file = result.files.first;
      if (file.bytes == null) {
        throw Exception('Could not read file');
      }

      final jsonString = utf8.decode(file.bytes!);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate it's a workout export (not full data export)
      if (data.containsKey('workout_session') && data.containsKey('workout_sets')) {
        // Single workout import
        final sessionData = data['workout_session'] as Map<String, dynamic>;
        final workoutName = sessionData['name'] ?? 'Imported Workout';

        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text(
              'Import Workout',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            content: Text(
              'Import workout "$workoutName"?',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Import', style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
        );

        if (confirmed != true) {
          setState(() => _isImporting = false);
          return;
        }

        final workoutId = await _exportService.importSingleWorkout(data);

        // Refresh providers
        ref.invalidate(allWorkoutSessionsProvider);
        ref.invalidate(workoutSessionsGroupedProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Imported workout "$workoutName"'),
              backgroundColor: AppColors.success,
              action: SnackBarAction(
                label: 'View',
                textColor: Colors.white,
                onPressed: () {
                  context.push('/workout-detail/$workoutId');
                },
              ),
            ),
          );
        }
      } else {
        throw Exception('Invalid workout file format. Please select a workout export file.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing workout: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isImporting = false);
    }
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.info, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Export Your Data',
                  style: TextStyle(
                    color: AppColors.info,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Export all your workout data, exercises, goals, and progress to a JSON file. You can save it as a backup or use it to migrate to another device.',
                  style: TextStyle(
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

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Data',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.fitness_center,
                label: 'Workouts',
                value: _stats['workouts']?.toString() ?? '0',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.grid_on,
                label: 'Sets',
                value: _stats['sets']?.toString() ?? '0',
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.sports_gymnastics,
                label: 'Exercises',
                value: _stats['exercises']?.toString() ?? '0',
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.flag,
                label: 'Goals',
                value: _stats['targets']?.toString() ?? '0',
                color: AppColors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          icon: Icons.monitor_weight,
          label: 'Weight Entries',
          value: _stats['weight_entries']?.toString() ?? '0',
          color: AppColors.info,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
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

  Widget _buildExportSizeCard() {
    final sizeKB = (_exportSize / 1024).toStringAsFixed(2);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.storage, color: AppColors.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Export Size',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$sizeKB KB',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isExporting ? null : _exportData,
        icon: _isExporting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.upload),
        label: Text(
          _isExporting ? 'Exporting...' : 'Export All Data',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildImportButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isImporting ? null : _importWorkout,
        icon: _isImporting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.download),
        label: Text(
          _isImporting ? 'Importing...' : 'Import Workout',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
