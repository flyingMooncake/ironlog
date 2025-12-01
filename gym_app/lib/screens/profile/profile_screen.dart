import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../models/user_profile.dart';
import '../../providers/user_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _ageController = TextEditingController();

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

    return Scaffold(
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
          _buildInfoField(
            label: 'Weight (${profile.weightUnit})',
            controller: _weightController,
            keyboardType: TextInputType.number,
            onChanged: (value) => _saveProfile(profile, weight: double.tryParse(value)),
          ),
          const SizedBox(height: 16),
          _buildInfoField(
            label: 'Height (${profile.heightUnit})',
            controller: _heightController,
            keyboardType: TextInputType.number,
            onChanged: (value) => _saveProfile(profile, height: double.tryParse(value)),
          ),
          const SizedBox(height: 16),
          _buildInfoField(
            label: 'Age',
            controller: _ageController,
            keyboardType: TextInputType.number,
            onChanged: (value) => _saveProfile(profile, age: int.tryParse(value)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField({
    required String label,
    required TextEditingController controller,
    required TextInputType keyboardType,
    required Function(String) onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
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
      onChanged: onChanged,
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
            icon: Icons.download,
            title: 'Export Data',
            subtitle: 'Backup your workout data to JSON',
            onTap: () => context.push('/export'),
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
                    _saveProfile(profile, unitSystem: value);
                    Navigator.pop(context);
                  }
                },
              ),
              onTap: () {
                _saveProfile(profile, unitSystem: UnitSystem.metric);
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
                    _saveProfile(profile, unitSystem: value);
                    Navigator.pop(context);
                  }
                },
              ),
              onTap: () {
                _saveProfile(profile, unitSystem: UnitSystem.imperial);
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

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }
}
