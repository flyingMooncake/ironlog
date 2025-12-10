import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/colors.dart';
import '../../models/workout_template.dart';
import '../../models/template_group.dart';
import '../../providers/template_provider.dart';
import '../../providers/exercise_provider.dart';
import '../../repositories/template_repository.dart';
import '../../repositories/template_group_repository.dart';
import '../../services/haptic_service.dart';
import '../../services/favorites_service.dart';
import 'package:intl/intl.dart';
import 'template_analysis_screen.dart';

class TemplatesScreen extends ConsumerStatefulWidget {
  const TemplatesScreen({super.key});

  @override
  ConsumerState<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends ConsumerState<TemplatesScreen> {
  final Set<int?> _expandedGroups = {}; // null for ungrouped
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

  Future<void> _toggleFavorite(int groupId) async {
    await FavoritesService.instance.toggleFavorite(groupId);
    await _loadFavorites();
    HapticService.instance.light();
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(allTemplatesProvider);
    final groupsAsync = ref.watch(allTemplateGroupsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: templatesAsync.when(
          data: (templates) {
            return groupsAsync.when(
              data: (groups) {
                if (templates.isEmpty) {
                  return _buildEmptyState(context);
                }

                // Organize templates by group
                final Map<int?, List<WorkoutTemplate>> templatesByGroup = {};
                for (final template in templates) {
                  final groupId = template.groupId;
                  if (!templatesByGroup.containsKey(groupId)) {
                    templatesByGroup[groupId] = [];
                  }
                  templatesByGroup[groupId]!.add(template);
                }

                // Sort templates within each group by orderInGroup
                for (final templates in templatesByGroup.values) {
                  templates.sort((a, b) => a.orderInGroup.compareTo(b.orderInGroup));
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Show groups first (sorted by orderIndex)
                    ...groups.map((group) {
                      final groupTemplates = templatesByGroup[group.id] ?? [];
                      if (groupTemplates.isEmpty) return const SizedBox.shrink();
                      return _buildGroupSection(context, group, groupTemplates);
                    }),
                    // Show ungrouped templates
                    if (templatesByGroup[null]?.isNotEmpty ?? false)
                      _buildUngroupedSection(context, templatesByGroup[null]!),
                  ],
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
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'create_group',
            onPressed: () {
              HapticService.instance.medium();
              _showCreateGroupDialog(context);
            },
            backgroundColor: AppColors.surfaceElevated,
            child: const Icon(Icons.create_new_folder, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'create_template',
            onPressed: () {
              HapticService.instance.medium();
              _showCreateTemplateDialog(context);
            },
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.add),
            label: const Text('Template'),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupSection(BuildContext context, TemplateGroup group, List<WorkoutTemplate> templates) {
    final isExpanded = _expandedGroups.contains(group.id);
    final isFavorite = _favoriteGroupIds.contains(group.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticService.instance.light();
                setState(() {
                  if (isExpanded) {
                    _expandedGroups.remove(group.id);
                  } else {
                    _expandedGroups.add(group.id);
                  }
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      isExpanded ? Icons.folder_open : Icons.folder,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${templates.length} workout${templates.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.star : Icons.star_border,
                        color: isFavorite ? AppColors.warning : AppColors.textMuted,
                      ),
                      onPressed: () => _toggleFavorite(group.id!),
                      tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
                    ),
                    PopupMenuButton(
                      icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
                      color: AppColors.surface,
                      itemBuilder: (context) => <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'rename',
                          child: const Row(
                            children: [
                              Icon(Icons.edit, color: AppColors.primary, size: 20),
                              SizedBox(width: 12),
                              Text('Rename', style: TextStyle(color: AppColors.textPrimary)),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'share',
                          child: const Row(
                            children: [
                              Icon(Icons.share, color: AppColors.primary, size: 20),
                              SizedBox(width: 12),
                              Text('Share', style: TextStyle(color: AppColors.textPrimary)),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'export',
                          child: const Row(
                            children: [
                              Icon(Icons.upload, color: AppColors.info, size: 20),
                              SizedBox(width: 12),
                              Text('Export', style: TextStyle(color: AppColors.textPrimary)),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: const Row(
                            children: [
                              Icon(Icons.delete, color: AppColors.error, size: 20),
                              SizedBox(width: 12),
                              Text('Delete', style: TextStyle(color: AppColors.error)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'rename') {
                          _renameGroup(context, group);
                        } else if (value == 'delete') {
                          _deleteGroup(context, group);
                        } else if (value == 'share') {
                          _shareGroup(context, group, templates);
                        } else if (value == 'export') {
                          _exportGroup(context, group, templates);
                        }
                      },
                    ),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isExpanded)
            ...templates.map((template) => _buildTemplateCard(context, template, isInGroup: true)),
        ],
      ),
    );
  }

  Widget _buildUngroupedSection(BuildContext context, List<WorkoutTemplate> templates) {
    final isExpanded = _expandedGroups.contains(null);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticService.instance.light();
                setState(() {
                  if (isExpanded) {
                    _expandedGroups.remove(null);
                  } else {
                    _expandedGroups.add(null);
                  }
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.list,
                      color: AppColors.textSecondary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ungrouped',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${templates.length} workout${templates.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isExpanded)
            ...templates.map((template) => _buildTemplateCard(context, template, isInGroup: true)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
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
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create a template to quickly start workouts',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(BuildContext context, WorkoutTemplate template, {bool isInGroup = false}) {
    return Container(
      margin: isInGroup
          ? const EdgeInsets.only(left: 16, right: 16, bottom: 12)
          : const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isInGroup ? AppColors.surfaceElevated : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: isInGroup ? null : Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticService.instance.light();
            _startWorkoutFromTemplate(context, template);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        children: [
                          Text(
                            '${template.exercises.length} exercises',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          if (template.lastUsed != null)
                            Text(
                              '• ${_formatDate(template.lastUsed!)}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert, color: AppColors.textMuted, size: 20),
                  color: AppColors.surface,
                  itemBuilder: (context) => <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'analysis',
                      child: const Row(
                        children: [
                          Icon(Icons.analytics, color: AppColors.primary, size: 20),
                          SizedBox(width: 12),
                          Text('View Analysis', style: TextStyle(color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: const Row(
                        children: [
                          Icon(Icons.edit, color: AppColors.primary, size: 20),
                          SizedBox(width: 12),
                          Text('Edit', style: TextStyle(color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'move',
                      child: const Row(
                        children: [
                          Icon(Icons.drive_file_move, color: AppColors.primary, size: 20),
                          SizedBox(width: 12),
                          Text('Move to Group', style: TextStyle(color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'duplicate',
                      child: const Row(
                        children: [
                          Icon(Icons.content_copy, color: AppColors.primary, size: 20),
                          SizedBox(width: 12),
                          Text('Duplicate', style: TextStyle(color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: const Row(
                        children: [
                          Icon(Icons.delete, color: AppColors.error, size: 20),
                          SizedBox(width: 12),
                          Text('Delete', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'analysis') {
                      _viewAnalysis(context, template);
                    } else if (value == 'edit') {
                      _editTemplate(context, template);
                    } else if (value == 'move') {
                      _moveTemplateToGroup(context, template);
                    } else if (value == 'duplicate') {
                      _duplicateTemplate(context, template);
                    } else if (value == 'delete') {
                      _deleteTemplate(context, template);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) return 'today';
    if (difference.inDays == 1) return 'yesterday';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return DateFormat('MMM d').format(date);
  }

  void _showCreateGroupDialog(BuildContext context) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Create Group',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            labelText: 'Group Name',
            labelStyle: const TextStyle(color: AppColors.textSecondary),
            hintText: 'e.g., Upper Body, PPL Split',
            hintStyle: const TextStyle(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surfaceElevated,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a group name'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              final groupsAsync = ref.read(allTemplateGroupsProvider);
              final groups = groupsAsync.value ?? [];

              final group = TemplateGroup(
                name: nameController.text,
                orderIndex: groups.length,
              );

              final repo = ref.read(templateGroupRepositoryProvider);
              await repo.createGroup(group);
              ref.invalidate(allTemplateGroupsProvider);

              if (context.mounted) {
                Navigator.pop(context);
                HapticService.instance.success();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Group created'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Create', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    ).then((_) => nameController.dispose());
  }

  void _showCreateTemplateDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final groupsAsync = ref.read(allTemplateGroupsProvider);
    final groups = groupsAsync.value ?? [];
    int? selectedGroupId;

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Create Template',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Template Name',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    hintText: 'e.g., Push Day, Leg Day',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Description (optional)',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                if (groups.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Group (optional)',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int?>(
                        value: selectedGroupId,
                        isExpanded: true,
                        dropdownColor: AppColors.surface,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        hint: const Text(
                          'No group',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text(
                              'No group',
                              style: TextStyle(color: AppColors.textPrimary),
                            ),
                          ),
                          ...groups.map((group) => DropdownMenuItem<int?>(
                            value: group.id,
                            child: Text(
                              group.name,
                              style: const TextStyle(color: AppColors.textPrimary),
                            ),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedGroupId = value;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, {
                  'name': nameController.text,
                  'description': descriptionController.text,
                  'groupId': selectedGroupId,
                });
              },
              child: const Text('Create', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );

    nameController.dispose();
    descriptionController.dispose();

    if (result != null && result['name'].toString().isNotEmpty) {
      final template = WorkoutTemplate(
        name: result['name'],
        description: result['description'].toString().isEmpty
            ? null
            : result['description'],
        groupId: result['groupId'],
        exercises: [],
      );

      final repo = ref.read(templateRepositoryProvider);
      await repo.createTemplate(template);
      ref.invalidate(allTemplatesProvider);

      if (context.mounted) {
        HapticService.instance.success();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Template created'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  void _renameGroup(BuildContext context, TemplateGroup group) {
    final nameController = TextEditingController(text: group.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Rename Group',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            labelText: 'Group Name',
            labelStyle: const TextStyle(color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.surfaceElevated,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a group name'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              final updatedGroup = group.copyWith(name: nameController.text);
              final repo = ref.read(templateGroupRepositoryProvider);
              await repo.updateGroup(updatedGroup);
              ref.invalidate(allTemplateGroupsProvider);

              if (context.mounted) {
                Navigator.pop(context);
                HapticService.instance.success();
              }
            },
            child: const Text('Rename', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    ).then((_) => nameController.dispose());
  }

  void _deleteGroup(BuildContext context, TemplateGroup group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete Group',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Delete "${group.name}"? Workouts in this group will be moved to ungrouped.',
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

    if (confirmed == true && group.id != null) {
      final repo = ref.read(templateGroupRepositoryProvider);
      await repo.deleteGroup(group.id!);
      ref.invalidate(allTemplateGroupsProvider);
      ref.invalidate(allTemplatesProvider);

      if (context.mounted) {
        HapticService.instance.medium();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group deleted'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  void _moveTemplateToGroup(BuildContext context, WorkoutTemplate template) async {
    final groupsAsync = ref.read(allTemplateGroupsProvider);
    final groups = groupsAsync.value ?? [];

    final selectedGroupId = await showDialog<int?>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Move to Group',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.list, color: AppColors.textSecondary),
              title: const Text(
                'No group',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () => Navigator.pop(context, -1), // -1 means null
            ),
            const Divider(color: AppColors.surfaceHighlight),
            ...groups.map((group) => ListTile(
              leading: const Icon(Icons.folder, color: AppColors.primary),
              title: Text(
                group.name,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () => Navigator.pop(context, group.id),
            )),
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

    if (selectedGroupId != null) {
      final newGroupId = selectedGroupId == -1 ? null : selectedGroupId;
      final updatedTemplate = template.copyWith(groupId: newGroupId);

      final repo = ref.read(templateRepositoryProvider);
      await repo.updateTemplate(updatedTemplate);
      ref.invalidate(allTemplatesProvider);

      if (context.mounted) {
        HapticService.instance.success();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Template moved'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  void _deleteTemplate(BuildContext context, WorkoutTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete Template',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete "${template.name}"?',
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

    if (confirmed == true && template.id != null) {
      final repo = ref.read(templateRepositoryProvider);
      await repo.deleteTemplate(template.id!);
      ref.invalidate(allTemplatesProvider);

      if (context.mounted) {
        HapticService.instance.medium();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Template deleted'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  void _startWorkoutFromTemplate(BuildContext context, WorkoutTemplate template) async {
    final repo = ref.read(templateRepositoryProvider);
    await repo.markTemplateUsed(template.id!);

    HapticService.instance.medium();

    if (context.mounted) {
      context.go('/workout', extra: {
        'type': 'template',
        'templateId': template.id,
      });
    }
  }

  void _viewAnalysis(BuildContext context, WorkoutTemplate template) {
    HapticService.instance.light();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TemplateAnalysisScreen(template: template),
      ),
    );
  }

  void _editTemplate(BuildContext context, WorkoutTemplate template) {
    HapticService.instance.light();
    context.push('/template-editor/${template.id}');
  }

  void _duplicateTemplate(BuildContext context, WorkoutTemplate template) async {
    final nameController = TextEditingController(text: '${template.name} (Copy)');
    final descriptionController = TextEditingController(text: template.description ?? '');
    final groupsAsync = ref.read(allTemplateGroupsProvider);
    final groups = groupsAsync.value ?? [];
    int? selectedGroupId = template.groupId;

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Duplicate Template',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'New Template Name',
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
                TextField(
                  controller: descriptionController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Description (optional)',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                if (groups.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Group (optional)',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int?>(
                        value: selectedGroupId,
                        isExpanded: true,
                        dropdownColor: AppColors.surface,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        hint: const Text(
                          'No group',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text(
                              'No group',
                              style: TextStyle(color: AppColors.textPrimary),
                            ),
                          ),
                          ...groups.map((group) => DropdownMenuItem<int?>(
                            value: group.id,
                            child: Text(
                              group.name,
                              style: const TextStyle(color: AppColors.textPrimary),
                            ),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedGroupId = value;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, {
                'name': nameController.text,
                'description': descriptionController.text,
                'groupId': selectedGroupId,
              }),
              child: const Text('Duplicate', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );

    if (result != null && template.id != null) {
      // Create new exercises without IDs to avoid conflicts with existing exercises
      final newExercises = template.exercises.map((exercise) {
        return TemplateExercise(
          id: null,  // Remove ID to create new entries
          templateId: 0,  // Will be set by repository
          exerciseId: exercise.exerciseId,
          orderIndex: exercise.orderIndex,
          sets: exercise.sets,
          targetReps: exercise.targetReps,
          targetWeight: exercise.targetWeight,
          restSeconds: exercise.restSeconds,
          notes: exercise.notes,
        );
      }).toList();

      final newTemplate = WorkoutTemplate(
        name: result['name'],
        description: result['description'].isEmpty ? null : result['description'],
        groupId: result['groupId'],
        exercises: newExercises,
      );

      final repo = ref.read(templateRepositoryProvider);
      await repo.createTemplate(newTemplate);
      ref.invalidate(allTemplatesProvider);

      if (context.mounted) {
        HapticService.instance.success();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Created "${newTemplate.name}"'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }

    nameController.dispose();
    descriptionController.dispose();
  }

  void _shareGroup(BuildContext context, TemplateGroup group, List<WorkoutTemplate> templates) async {
    try {
      final buffer = StringBuffer();
      final exerciseRepo = ref.read(exerciseRepositoryProvider);

      // Header
      buffer.writeln('📋 ${group.name}');
      buffer.writeln('📊 ${templates.length} workout template${templates.length != 1 ? 's' : ''}');
      buffer.writeln('\n${'=' * 40}');

      // Templates
      for (int i = 0; i < templates.length; i++) {
        final template = templates[i];

        buffer.writeln('\n${i + 1}. ${template.name}');

        if (template.description != null && template.description!.isNotEmpty) {
          buffer.writeln('   📝 ${template.description}');
        }

        buffer.writeln('   Exercises: ${template.exercises.length}');
        buffer.writeln();

        // Load and display exercises
        for (int j = 0; j < template.exercises.length; j++) {
          final templateExercise = template.exercises[j];
          final exercise = await exerciseRepo.getExerciseById(templateExercise.exerciseId);

          if (exercise != null) {
            String exerciseLine = '   ${j + 1}. ${exercise.name}';

            // Add exercise details
            final details = <String>[];
            if (templateExercise.sets > 0) {
              details.add('${templateExercise.sets} sets');
            }
            if (templateExercise.targetReps != null) {
              details.add('${templateExercise.targetReps} reps');
            }
            if (templateExercise.targetWeight != null) {
              details.add('${templateExercise.targetWeight} kg');
            }
            if (templateExercise.restSeconds != null) {
              final minutes = templateExercise.restSeconds! ~/ 60;
              final seconds = templateExercise.restSeconds! % 60;
              if (minutes > 0) {
                details.add('${minutes}m${seconds > 0 ? '${seconds}s' : ''} rest');
              } else {
                details.add('${seconds}s rest');
              }
            }

            if (details.isNotEmpty) {
              exerciseLine += ' - ${details.join(', ')}';
            }

            buffer.writeln(exerciseLine);

            if (templateExercise.notes != null && templateExercise.notes!.isNotEmpty) {
              buffer.writeln('      💬 ${templateExercise.notes}');
            }
          }
        }
      }

      buffer.writeln('\n${'=' * 40}');
      buffer.writeln('\nShared from IronLog 💪');

      final text = buffer.toString();

      // Share the text
      Share.share(
        text,
        subject: 'IronLog Group: ${group.name}',
      );

      if (context.mounted) {
        HapticService.instance.light();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing group: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _exportGroup(BuildContext context, TemplateGroup group, List<WorkoutTemplate> templates) async {
    try {
      // Create export data
      final exportData = {
        'group': {
          'name': group.name,
          'orderIndex': group.orderIndex,
        },
        'templates': templates.map((t) => {
          'name': t.name,
          'description': t.description,
          'orderInGroup': t.orderInGroup,
          'exercises': t.exercises.map((e) => e.toMap()).toList(),
        }).toList(),
        'exportedAt': DateTime.now().toIso8601String(),
        'exportedFrom': 'IronLog',
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      final fileName = '${group.name.replaceAll(' ', '_')}_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.json';

      // Share the JSON file
      await Share.shareXFiles(
        [XFile.fromData(
          utf8.encode(jsonString),
          mimeType: 'application/json',
          name: fileName,
        )],
        subject: 'IronLog Group Export: ${group.name}',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group exported successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting group: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _importGroup(BuildContext context) async {
    try {
      // Pick JSON file
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

      // Validate data structure
      if (!data.containsKey('group') || !data.containsKey('templates')) {
        throw Exception('Invalid group export file');
      }

      final groupData = data['group'] as Map<String, dynamic>;
      final templatesData = data['templates'] as List<dynamic>;

      // Show confirmation dialog
      final groupName = groupData['name'] as String;
      final templateCount = templatesData.length;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Import Group',
            style: TextStyle(color: AppColors.textPrimary),
          ),
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

      // Create group
      final groupRepo = ref.read(templateGroupRepositoryProvider);
      final newGroup = TemplateGroup(
        name: groupName,
        orderIndex: groupData['orderIndex'] as int? ?? 0,
      );
      final groupId = await groupRepo.createGroup(newGroup);

      // Create templates
      final templateRepo = ref.read(templateRepositoryProvider);
      for (final templateData in templatesData) {
        final templateMap = templateData as Map<String, dynamic>;

        // Convert exercise maps to TemplateExercise objects
        final exercisesData = (templateMap['exercises'] as List<dynamic>);
        final exercises = exercisesData.map((e) {
          final exerciseMap = e as Map<String, dynamic>;
          return TemplateExercise.fromMap(exerciseMap);
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

      // Refresh providers
      ref.invalidate(allTemplatesProvider);
      ref.invalidate(allTemplateGroupsProvider);

      if (context.mounted) {
        HapticService.instance.success();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported group "$groupName" with $templateCount template${templateCount == 1 ? '' : 's'}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
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
