import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/colors.dart';
import '../../models/user_profile.dart';
import '../../models/template_group.dart';
import '../../models/workout_template.dart';
import '../../providers/user_provider.dart';
import '../../providers/template_provider.dart';
import '../../repositories/template_repository.dart';
import '../../repositories/template_group_repository.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _ageController = TextEditingController();
  int _updateCount = 0;

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: profileAsync.when(
          data: (profile) => _buildProfileContent(profile),
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (error, stack) => Center(
            child: Text(
              'Error loading profile',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent(UserProfile profile) {
    // Initialize controllers with profile data
    if (_weightController.text.isEmpty && profile.weight != null) {
      _weightController.text = profile.weight.toString();
    }
    if (_heightController.text.isEmpty && profile.height != null) {
      _heightController.text = profile.height.toString();
    }
    if (_ageController.text.isEmpty && profile.age != null) {
      _ageController.text = profile.age.toString();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personal Info Section
          _buildSectionHeader('Personal Information'),
          const SizedBox(height: 16),
          _buildInfoCard(profile),

          const SizedBox(height: 24),

          // Settings Section
          _buildSectionHeader('Settings'),
          const SizedBox(height: 16),
          _buildSettingsCard(profile),

          const SizedBox(height: 24),

          // Data Section
          _buildSectionHeader('Data'),
          const SizedBox(height: 16),
          _buildDataCard(),

          const SizedBox(height: 24),

          // About Section
          _buildAboutCard(),
        ],
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

  Widget _buildInfoCard(UserProfile profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildNumberField(
            label: 'Weight (${profile.weightUnit})',
            controller: _weightController,
            isDecimal: true,
            onSubmitted: () => _saveProfile(profile, weight: double.tryParse(_weightController.text), showSnackBar: true),
          ),
          const SizedBox(height: 16),
          _buildNumberField(
            label: 'Height (${profile.heightUnit})',
            controller: _heightController,
            isDecimal: true,
            onSubmitted: () => _saveProfile(profile, height: double.tryParse(_heightController.text), showSnackBar: true),
          ),
          const SizedBox(height: 16),
          _buildNumberField(
            label: 'Age',
            controller: _ageController,
            isDecimal: false,
            onSubmitted: () => _saveProfile(profile, age: int.tryParse(_ageController.text), showSnackBar: true),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required TextEditingController controller,
    required bool isDecimal,
    required VoidCallback onSubmitted,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isDecimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: (value) {
        // Apply same number input logic as workout screen
        String normalizedValue = value;

        if (isDecimal) {
          // Replace comma with dot
          normalizedValue = normalizedValue.replaceAll(',', '.');

          // Replace multiple consecutive dots with single dot
          normalizedValue = normalizedValue.replaceAll(RegExp(r'\.{2,}'), '.');

          // Remove extra decimal points (keep only the first one)
          final parts = normalizedValue.split('.');
          if (parts.length > 2) {
            normalizedValue = '${parts[0]}.${parts.sublist(1).join('')}';
          }

          // Remove leading zeros except for decimal values like "0.5"
          if (normalizedValue.isNotEmpty &&
              normalizedValue.startsWith('0') &&
              normalizedValue.length > 1 &&
              !normalizedValue.startsWith('0.')) {
            normalizedValue = normalizedValue.replaceFirst(RegExp(r'^0+'), '');
            if (normalizedValue.isEmpty || normalizedValue.startsWith('.')) {
              normalizedValue = '0$normalizedValue';
            }
          }
        } else {
          // For integer fields, remove leading zeros
          if (normalizedValue.isNotEmpty && normalizedValue.startsWith('0') && normalizedValue.length > 1) {
            normalizedValue = normalizedValue.replaceFirst(RegExp(r'^0+'), '');
          }
        }

        if (normalizedValue != value) {
          controller.value = TextEditingValue(
            text: normalizedValue,
            selection: TextSelection.collapsed(offset: normalizedValue.length),
          );
        }
      },
      onSubmitted: (_) => onSubmitted(),
    );
  }

  Widget _buildSettingsCard(UserProfile profile) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.monitor_weight,
            title: 'Bodyweight Tracking',
            subtitle: 'Track weight over time',
            onTap: () => context.push('/bodyweight'),
          ),
          const Divider(color: AppColors.surfaceHighlight, height: 1),
          _buildSettingsTile(
            icon: Icons.straighten,
            title: 'Body Measurements',
            subtitle: 'Track measurements over time',
            onTap: () => context.push('/body-measurements'),
          ),
          const Divider(color: AppColors.surfaceHighlight, height: 1),
          _buildSettingsTile(
            icon: Icons.emoji_events,
            title: 'Personal Records',
            subtitle: 'View your PRs and achievements',
            onTap: () => context.push('/personal-records'),
          ),
          const Divider(color: AppColors.surfaceHighlight, height: 1),
          _buildSettingsTile(
            icon: Icons.photo_camera,
            title: 'Progress Photos',
            subtitle: 'Track visual progress with photos',
            onTap: () => context.push('/progress-photos'),
          ),
          const Divider(color: AppColors.surfaceHighlight, height: 1),
          _buildSettingsTile(
            icon: Icons.calendar_month,
            title: 'Workout Calendar',
            subtitle: 'Schedule workouts and rest days',
            onTap: () => context.push('/workout-calendar'),
          ),
          const Divider(color: AppColors.surfaceHighlight, height: 1),
          _buildSettingsTile(
            icon: Icons.straighten,
            title: 'Unit System',
            subtitle: profile.unitSystem == UnitSystem.metric ? 'Metric (kg, cm)' : 'Imperial (lbs, in)',
            onTap: () => _showUnitSystemDialog(profile),
          ),
          const Divider(color: AppColors.surfaceHighlight, height: 1),
          _buildSettingsTile(
            icon: Icons.timer,
            title: 'Rest Timer',
            subtitle: profile.autoStartRestTimer
                ? 'Auto-start (${profile.restTimerDefault}s)'
                : 'Disabled',
            onTap: () => _showRestTimerDialog(profile),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
      onTap: onTap,
    );
  }

  Widget _buildDataCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.analytics,
            title: 'Statistics',
            subtitle: 'View workout analytics and progress',
            onTap: () => context.push('/statistics'),
          ),
          const Divider(color: AppColors.surfaceHighlight, height: 1),
          _buildSettingsTile(
            icon: Icons.upload,
            title: 'Export Data',
            subtitle: 'Backup groups or all workout data',
            onTap: () => _showExportOptions(context),
          ),
          const Divider(color: AppColors.surfaceHighlight, height: 1),
          _buildSettingsTile(
            icon: Icons.download,
            title: 'Import Data',
            subtitle: 'Import groups or workouts from JSON',
            onTap: () => _showImportOptions(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fitness_center, color: AppColors.primary, size: 32),
              const SizedBox(width: 12),
              const Text(
                'IronLog',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Free gym tracker. No ads. No subscriptions. Ever.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Version 1.0.0',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showUnitSystemDialog(UserProfile profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Unit System',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Metric (kg, cm)', style: TextStyle(color: AppColors.textPrimary)),
              leading: Radio<UnitSystem>(
                value: UnitSystem.metric,
                groupValue: profile.unitSystem,
                activeColor: AppColors.primary,
                onChanged: (value) {
                  if (value != null) {
                    _saveProfile(profile, unitSystem: value, showSnackBar: true);
                    Navigator.pop(context);
                  }
                },
              ),
              onTap: () {
                _saveProfile(profile, unitSystem: UnitSystem.metric, showSnackBar: true);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Imperial (lbs, in)', style: TextStyle(color: AppColors.textPrimary)),
              leading: Radio<UnitSystem>(
                value: UnitSystem.imperial,
                groupValue: profile.unitSystem,
                activeColor: AppColors.primary,
                onChanged: (value) {
                  if (value != null) {
                    _saveProfile(profile, unitSystem: value, showSnackBar: true);
                    Navigator.pop(context);
                  }
                },
              ),
              onTap: () {
                _saveProfile(profile, unitSystem: UnitSystem.imperial, showSnackBar: true);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRestTimerDialog(UserProfile profile) {
    final controller = TextEditingController(text: profile.restTimerDefault.toString());
    bool autoStart = profile.autoStartRestTimer;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Rest Timer Settings',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text(
                  'Auto-start rest timer',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                subtitle: const Text(
                  'Automatically start timer after completing a set',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                value: autoStart,
                activeColor: AppColors.primary,
                onChanged: (value) {
                  setState(() {
                    autoStart = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Default Duration (seconds)',
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
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                final seconds = int.tryParse(controller.text);
                if (seconds != null && seconds > 0) {
                  _saveProfile(
                    profile,
                    restTimerDefault: seconds,
                    autoStartRestTimer: autoStart,
                    showSnackBar: true,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Save', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    ).then((_) => controller.dispose());
  }

  void _saveProfile(
    UserProfile profile, {
    double? weight,
    double? height,
    int? age,
    UnitSystem? unitSystem,
    int? restTimerDefault,
    bool? autoStartRestTimer,
    bool showSnackBar = false,
  }) async {
    final updated = UserProfile(
      id: profile.id,
      weight: weight ?? profile.weight,
      height: height ?? profile.height,
      age: age ?? profile.age,
      unitSystem: unitSystem ?? profile.unitSystem,
      restTimerDefault: restTimerDefault ?? profile.restTimerDefault,
      autoStartRestTimer: autoStartRestTimer ?? profile.autoStartRestTimer,
    );

    final repo = ref.read(userRepositoryProvider);
    await repo.saveUserProfile(updated);

    // Refresh the provider
    ref.invalidate(userProfileProvider);

    // Only show snackbar when explicitly requested (not on every keystroke)
    if (mounted && showSnackBar) {
      _updateCount++;

      // Only show SnackBar occasionally to avoid spam
      // Show on first update, then every 5 updates after that
      final shouldShow = _updateCount == 1 || _updateCount % 5 == 0;

      if (shouldShow) {
        // Show a more subtle, brief SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.check_circle, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Saved', style: TextStyle(fontSize: 13)),
              ],
            ),
            backgroundColor: AppColors.success.withOpacity(0.85),
            duration: const Duration(milliseconds: 800),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        );
      }
    }
  }

  void _showExportOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Export Data',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.folder, color: AppColors.primary),
              title: const Text('Export Template Group', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: const Text('Choose a group to export', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                context.push('/templates'); // User can export from templates screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Go to a group\'s menu and select Export'),
                    backgroundColor: AppColors.info,
                  ),
                );
              },
            ),
            const Divider(color: AppColors.surfaceHighlight),
            ListTile(
              leading: const Icon(Icons.cloud_upload, color: AppColors.success),
              title: const Text('Export All Data', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: const Text('Full backup of all data', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                context.push('/export');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }

  void _showImportOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Import Data',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.folder, color: AppColors.primary),
              title: const Text('Import Template Group', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: const Text('Import group from JSON file', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              onTap: () async {
                Navigator.pop(context);
                // Call the import group method from templates screen
                await _importGroupFromProfile(context);
              },
            ),
            const Divider(color: AppColors.surfaceHighlight),
            ListTile(
              leading: const Icon(Icons.fitness_center, color: AppColors.success),
              title: const Text('Import Workout', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: const Text('Import single workout', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                context.push('/export'); // The export screen has import workout button
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }

  Future<void> _importGroupFromProfile(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null) {
        throw Exception('Could not read file');
      }

      final jsonString = utf8.decode(file.bytes!);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      if (!data.containsKey('group') || !data.containsKey('templates')) {
        throw Exception('Invalid group export file');
      }

      final groupData = data['group'] as Map<String, dynamic>;
      final templatesData = data['templates'] as List<dynamic>;
      final groupName = groupData['name'] as String;
      final templateCount = templatesData.length;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Import Group', style: TextStyle(color: AppColors.textPrimary)),
          content: Text(
            'Import group "$groupName" with $templateCount template${templateCount == 1 ? '' : 's'}?',
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

      if (confirmed != true) return;

      final groupRepo = ref.read(templateGroupRepositoryProvider);
      final templateRepo = ref.read(templateRepositoryProvider);

      final newGroup = TemplateGroup(
        name: groupName,
        orderIndex: groupData['orderIndex'] as int? ?? 0,
      );
      final groupId = await groupRepo.createGroup(newGroup);

      for (final templateData in templatesData) {
        final templateMap = templateData as Map<String, dynamic>;
        final exercisesData = (templateMap['exercises'] as List<dynamic>);
        final exercises = exercisesData.map((e) {
          return TemplateExercise.fromMap(e as Map<String, dynamic>);
        }).toList();

        final template = WorkoutTemplate(
          name: templateMap['name'] as String,
          description: templateMap['description'] as String?,
          groupId: groupId,
          orderInGroup: templateMap['orderInGroup'] as int? ?? 0,
          exercises: exercises,
        );

        await templateRepo.createTemplate(template);
      }

      ref.invalidate(allTemplatesProvider);
      ref.invalidate(allTemplateGroupsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported group "$groupName" with $templateCount template${templateCount == 1 ? '' : 's'}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing group: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
