import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/colors.dart';
import '../models/workout_template.dart';
import '../models/workout_session.dart';
import '../models/template_group.dart';
import '../providers/template_provider.dart';
import '../repositories/workout_repository.dart';
import '../services/haptic_service.dart';
import '../services/favorites_service.dart';
import 'package:intl/intl.dart';

class StartWorkoutDialog extends ConsumerStatefulWidget {
  const StartWorkoutDialog({super.key});

  @override
  ConsumerState<StartWorkoutDialog> createState() => _StartWorkoutDialogState();
}

class _StartWorkoutDialogState extends ConsumerState<StartWorkoutDialog> {
  int _selectedTab = 0; // 0: Empty, 1: Template, 2: History
  int? _selectedGroupId; // null means showing groups, non-null means showing templates in that group
  bool _showingUngrouped = false;
  Set<int> _favoriteGroupIds = {};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final favorites = await FavoritesService.instance.getFavorites();
    setState(() {
      _favoriteGroupIds = favorites;
    });
  }

  void _backToGroups() {
    setState(() {
      _selectedGroupId = null;
      _showingUngrouped = false;
    });
  }

  Future<void> _toggleFavorite(int groupId) async {
    await FavoritesService.instance.toggleFavorite(groupId);
    await _loadFavorites();
    HapticService.instance.light();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Start Workout',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
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
            ),

            // Tab selector
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildTab('Empty', 0, Icons.add_circle_outline),
                  _buildTab('Templates', 1, Icons.note_alt_outlined),
                  _buildTab('History', 2, Icons.history),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Content
            Expanded(
              child: IndexedStack(
                index: _selectedTab,
                children: [
                  _buildEmptyTab(),
                  _buildTemplatesTab(),
                  _buildHistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index, IconData icon) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticService.instance.light();
          setState(() => _selectedTab = index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.fitness_center,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Quick Start',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start a blank workout and add exercises as you go',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticService.instance.medium();
                  Navigator.pop(context);
                  context.go('/workout');
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Empty Workout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatesTab() {
    // If a group is selected, show templates in that group
    if (_selectedGroupId != null || _showingUngrouped) {
      return _buildTemplatesList();
    }

    // Otherwise show groups
    return _buildGroupsList();
  }

  Widget _buildGroupsList() {
    final templatesAsync = ref.watch(allTemplatesProvider);
    final groupsAsync = ref.watch(allTemplateGroupsProvider);

    return templatesAsync.when(
      data: (templates) {
        return groupsAsync.when(
          data: (groups) {
            if (templates.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.note_alt_outlined,
                        size: 64,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No templates yet',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Create templates to quickly start workouts',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          context.push('/templates');
                        },
                        icon: const Icon(Icons.add, color: AppColors.primary),
                        label: const Text('Create Template'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Count ungrouped templates
            final ungroupedCount = templates.where((t) => t.groupId == null).length;

            // Build list of groups with template counts
            final groupsWithCounts = <Map<String, dynamic>>[];
            for (final group in groups) {
              final templatesInGroup = templates.where((t) => t.groupId == group.id).length;
              if (templatesInGroup > 0) {
                groupsWithCounts.add({
                  'group': group,
                  'count': templatesInGroup,
                  'isFavorite': _favoriteGroupIds.contains(group.id),
                });
              }
            }

            // Sort: favorites first, then by name
            groupsWithCounts.sort((a, b) {
              final aFavorite = a['isFavorite'] as bool;
              final bFavorite = b['isFavorite'] as bool;

              if (aFavorite && !bFavorite) return -1;
              if (!aFavorite && bFavorite) return 1;

              final aGroup = a['group'] as TemplateGroup;
              final bGroup = b['group'] as TemplateGroup;
              return aGroup.name.compareTo(bGroup.name);
            });

            // Build list of group widgets
            final groupItems = <Widget>[];

            // Add sorted groups
            for (final item in groupsWithCounts) {
              groupItems.add(_buildGroupItem(
                item['group'] as TemplateGroup,
                item['count'] as int,
              ));
            }

            // Add ungrouped as a special group if there are ungrouped templates
            if (ungroupedCount > 0) {
              groupItems.add(_buildUngroupedItem(ungroupedCount));
            }

            if (groupItems.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_outlined,
                        size: 64,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No template groups',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: groupItems,
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (error, stack) => Center(
            child: Text(
              'Error loading groups',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (error, stack) => Center(
        child: Text(
          'Error loading templates',
          style: const TextStyle(color: AppColors.error),
        ),
      ),
    );
  }

  Widget _buildGroupItem(TemplateGroup group, int templateCount) {
    final isFavorite = _favoriteGroupIds.contains(group.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: isFavorite
            ? Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5)
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.folder, color: AppColors.primary),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                group.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                isFavorite ? Icons.star : Icons.star_border,
                color: isFavorite ? AppColors.warning : AppColors.textMuted,
                size: 20,
              ),
              onPressed: () => _toggleFavorite(group.id!),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        subtitle: Text(
          '$templateCount ${templateCount == 1 ? 'template' : 'templates'}',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
        onTap: () {
          HapticService.instance.light();
          setState(() {
            _selectedGroupId = group.id;
            _showingUngrouped = false;
          });
        },
      ),
    );
  }

  Widget _buildUngroupedItem(int templateCount) {
    final isFavorite = _favoriteGroupIds.contains(-1); // -1 for ungrouped

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: isFavorite
            ? Border.all(color: AppColors.info.withOpacity(0.3), width: 1.5)
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.folder_open, color: AppColors.info),
        ),
        title: Row(
          children: [
            const Expanded(
              child: Text(
                'Ungrouped',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                isFavorite ? Icons.star : Icons.star_border,
                color: isFavorite ? AppColors.warning : AppColors.textMuted,
                size: 20,
              ),
              onPressed: () async {
                await FavoritesService.instance.toggleUngroupedFavorite();
                await _loadFavorites();
                HapticService.instance.light();
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        subtitle: Text(
          '$templateCount ${templateCount == 1 ? 'template' : 'templates'}',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
        onTap: () {
          HapticService.instance.light();
          setState(() {
            _selectedGroupId = null;
            _showingUngrouped = true;
          });
        },
      ),
    );
  }

  Widget _buildTemplatesList() {
    final templatesAsync = ref.watch(allTemplatesProvider);

    return templatesAsync.when(
      data: (templates) {
        // Filter templates based on selected group or ungrouped
        final filteredTemplates = _showingUngrouped
            ? templates.where((t) => t.groupId == null).toList()
            : templates.where((t) => t.groupId == _selectedGroupId).toList();

        return Column(
          children: [
            // Back button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    onPressed: _backToGroups,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _showingUngrouped ? 'Ungrouped Templates' : 'Templates',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filteredTemplates.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.note_alt_outlined,
                              size: 64,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No templates in this group',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: filteredTemplates.length,
                      itemBuilder: (context, index) {
                        final template = filteredTemplates[index];
                        return _buildTemplateItem(template);
                      },
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (error, stack) => Center(
        child: Text(
          'Error loading templates',
          style: const TextStyle(color: AppColors.error),
        ),
      ),
    );
  }

  Widget _buildTemplateItem(WorkoutTemplate template) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.fitness_center, color: AppColors.primary),
        ),
        title: Text(
          template.name,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${template.exercises.length} exercises',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
        onTap: () {
          HapticService.instance.medium();
          Navigator.pop(context);
          context.go('/workout', extra: {
            'type': 'template',
            'templateId': template.id,
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Loaded "${template.name}"'),
              backgroundColor: AppColors.success,
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryTab() {
    final workoutRepo = WorkoutRepository();

    return FutureBuilder<List<WorkoutSession>>(
      future: workoutRepo.getAllWorkoutSessions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading history',
              style: const TextStyle(color: AppColors.error),
            ),
          );
        }

        final sessions = snapshot.data ?? [];

        if (sessions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No workout history',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Complete a workout to see it here',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: sessions.length > 10 ? 10 : sessions.length,
          itemBuilder: (context, index) {
            final session = sessions[index];
            return _buildHistoryItem(session);
          },
        );
      },
    );
  }

  Widget _buildHistoryItem(WorkoutSession session) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.history, color: AppColors.info),
        ),
        title: Text(
          session.name ?? 'Workout',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          DateFormat('MMM d, y • h:mm a').format(session.startedAt),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
        onTap: () {
          HapticService.instance.medium();
          Navigator.pop(context);
          context.go('/workout', extra: {
            'type': 'history',
            'sessionId': session.id,
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Loaded workout from history'),
              backgroundColor: AppColors.success,
            ),
          );
        },
      ),
    );
  }
}
