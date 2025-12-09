import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/exercise.dart';
import '../../providers/exercise_provider.dart';
import '../../core/theme/colors.dart';
import '../../repositories/exercise_repository.dart';
import '../../widgets/one_rm_calculator.dart';
import '../../widgets/plate_calculator.dart';

class ExercisesScreen extends ConsumerStatefulWidget {
  const ExercisesScreen({super.key});

  @override
  ConsumerState<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends ConsumerState<ExercisesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(exerciseFilterProvider);
    final exercisesAsync = ref.watch(filteredExercisesProvider(filter));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
        children: [
          _buildSearchBar(),
          const SizedBox(height: 8),
          _buildMuscleGroupFilter(),
          const SizedBox(height: 16),
          Expanded(
            child: exercisesAsync.when(
              data: (exercises) => _buildExerciseList(exercises),
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading exercises',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: const TextStyle(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateExerciseDialog(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Create Exercise'),
      ),
    );
  }

  void _showCreateExerciseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CreateExerciseDialog(
        onExerciseCreated: () {
          // Refresh the exercises list
          ref.invalidate(allExercisesProvider);
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
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
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Search exercises...',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search, color: AppColors.primary, size: 24),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.textMuted),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                            });
                            ref.read(exerciseFilterProvider.notifier).setSearchQuery(null);
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                onChanged: (value) {
                  setState(() {});
                  ref
                      .read(exerciseFilterProvider.notifier)
                      .setSearchQuery(value.isEmpty ? null : value);
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
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
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.calculate, color: AppColors.textPrimary),
              tooltip: 'Calculators',
              onSelected: (value) {
                if (value == '1rm') {
                  showDialog(
                    context: context,
                    builder: (context) => const OneRMCalculator(),
                  );
                } else if (value == 'plates') {
                  showDialog(
                    context: context,
                    builder: (context) => const PlateCalculator(),
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: '1rm',
                  child: Row(
                    children: [
                      Icon(Icons.trending_up, color: AppColors.primary, size: 20),
                      SizedBox(width: 12),
                      Text('1RM Calculator'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'plates',
                  child: Row(
                    children: [
                      Icon(Icons.fitness_center, color: AppColors.primary, size: 20),
                      SizedBox(width: 12),
                      Text('Plate Calculator'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMuscleGroupFilter() {
    final selectedMuscle = ref.watch(exerciseFilterProvider).muscleGroup;

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip(
            label: 'All',
            isSelected: selectedMuscle == null,
            onTap: () {
              ref.read(exerciseFilterProvider.notifier).setMuscleGroup(null);
            },
          ),
          const SizedBox(width: 8),
          ...MuscleGroup.values.map((muscle) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildFilterChip(
                label: muscle.displayName,
                isSelected: selectedMuscle == muscle,
                onTap: () {
                  ref.read(exerciseFilterProvider.notifier).setMuscleGroup(muscle);
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.surfaceHighlight,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseList(List<Exercise> exercises) {
    if (exercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            const Text(
              'No exercises found',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try adjusting your filters',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '${exercises.length} ${exercises.length == 1 ? 'Exercise' : 'Exercises'}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final exercise = exercises[index];
              return _buildExerciseCard(exercise);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseCard(Exercise exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.push('/exercise-progress/${exercise.id}');
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon based on equipment
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getEquipmentIcon(exercise.equipment),
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _buildBadge(
                            exercise.primaryMuscle.displayName,
                            AppColors.primary,
                            icon: Icons.local_fire_department,
                          ),
                          if (exercise.equipment != null)
                            _buildBadge(
                              exercise.equipment!.displayName,
                              AppColors.info,
                              icon: Icons.fitness_center,
                            ),
                          _buildBadge(
                            exercise.trackingType.displayName,
                            AppColors.success,
                            icon: Icons.trending_up,
                          ),
                        ],
                      ),
                      if (exercise.secondaryMuscles.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: exercise.secondaryMuscles
                              .map((muscle) => _buildSmallBadge(muscle.displayName))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
                  color: AppColors.surface,
                  itemBuilder: (context) => <PopupMenuEntry<String>>[
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
                    if (value == 'edit') {
                      _showEditExerciseDialog(context, exercise);
                    } else if (value == 'delete') {
                      _deleteExercise(context, exercise);
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

  void _showEditExerciseDialog(BuildContext context, Exercise exercise) {
    showDialog(
      context: context,
      builder: (context) => CreateExerciseDialog(
        exercise: exercise,
        onExerciseCreated: () {
          ref.invalidate(allExercisesProvider);
        },
      ),
    );
  }

  Future<void> _deleteExercise(BuildContext context, Exercise exercise) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete Exercise',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete "${exercise.name}"?',
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

    if (confirmed == true && exercise.id != null) {
      final repo = ref.read(exerciseRepositoryProvider);
      await repo.deleteExercise(exercise.id!);
      ref.invalidate(allExercisesProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exercise deleted'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  IconData _getEquipmentIcon(Equipment? equipment) {
    switch (equipment) {
      case Equipment.barbell:
        return Icons.fitness_center;
      case Equipment.dumbbell:
        return Icons.fitness_center;
      case Equipment.machine:
        return Icons.settings;
      case Equipment.cable:
        return Icons.cable;
      case Equipment.bodyweight:
        return Icons.accessibility_new;
      case Equipment.kettlebell:
        return Icons.sports_gymnastics;
      case Equipment.bands:
        return Icons.linear_scale;
      default:
        return Icons.sports;
    }
  }

  Widget _buildBadge(String label, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class CreateExerciseDialog extends StatefulWidget {
  final VoidCallback onExerciseCreated;
  final Exercise? exercise;

  const CreateExerciseDialog({
    super.key,
    required this.onExerciseCreated,
    this.exercise,
  });

  @override
  State<CreateExerciseDialog> createState() => _CreateExerciseDialogState();
}

class _CreateExerciseDialogState extends State<CreateExerciseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  final ExerciseRepository _exerciseRepo = ExerciseRepository();

  late MuscleGroup _selectedPrimaryMuscle;
  late Equipment _selectedEquipment;
  late TrackingType _selectedTrackingType;
  final List<MuscleGroup> _selectedSecondaryMuscles = [];

  @override
  void initState() {
    super.initState();
    if (widget.exercise != null) {
      // Editing existing exercise
      _nameController.text = widget.exercise!.name;
      _notesController.text = widget.exercise!.notes ?? '';
      _selectedPrimaryMuscle = widget.exercise!.primaryMuscle;
      _selectedEquipment = widget.exercise!.equipment ?? Equipment.barbell;
      _selectedTrackingType = widget.exercise!.trackingType;
      _selectedSecondaryMuscles.addAll(widget.exercise!.secondaryMuscles);
    } else {
      // Creating new exercise - set defaults
      _selectedPrimaryMuscle = MuscleGroup.chest;
      _selectedEquipment = Equipment.barbell;
      _selectedTrackingType = TrackingType.weightReps;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.exercise != null ? 'Edit Exercise' : 'Create Custom Exercise',
                        style: const TextStyle(
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
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Exercise Name *',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an exercise name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<MuscleGroup>(
                  value: _selectedPrimaryMuscle,
                  decoration: InputDecoration(
                    labelText: 'Primary Muscle *',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: AppColors.textPrimary),
                  items: MuscleGroup.values.map((muscle) {
                    return DropdownMenuItem(
                      value: muscle,
                      child: Text(muscle.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedPrimaryMuscle = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Equipment>(
                  value: _selectedEquipment,
                  decoration: InputDecoration(
                    labelText: 'Equipment *',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: AppColors.textPrimary),
                  items: Equipment.values.map((equipment) {
                    return DropdownMenuItem(
                      value: equipment,
                      child: Text(equipment.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedEquipment = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TrackingType>(
                  value: _selectedTrackingType,
                  decoration: InputDecoration(
                    labelText: 'Tracking Type *',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: AppColors.textPrimary),
                  items: TrackingType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedTrackingType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Secondary Muscles (Optional)',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: MuscleGroup.values.map((muscle) {
                    final isSelected = _selectedSecondaryMuscles.contains(muscle);
                    return FilterChip(
                      label: Text(muscle.displayName),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedSecondaryMuscles.add(muscle);
                          } else {
                            _selectedSecondaryMuscles.remove(muscle);
                          }
                        });
                      },
                      backgroundColor: AppColors.surfaceElevated,
                      selectedColor: AppColors.primary.withOpacity(0.3),
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      ),
                      checkmarkColor: AppColors.primary,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Notes (Optional)',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _createExercise,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(widget.exercise != null ? 'Save' : 'Create'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _createExercise() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final exercise = Exercise(
      id: widget.exercise?.id,
      name: _nameController.text.trim(),
      primaryMuscle: _selectedPrimaryMuscle,
      secondaryMuscles: _selectedSecondaryMuscles,
      trackingType: _selectedTrackingType,
      equipment: _selectedEquipment,
      isCustom: true,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    try {
      if (widget.exercise != null) {
        // Update existing exercise
        await _exerciseRepo.updateExercise(exercise);
      } else {
        // Create new exercise
        await _exerciseRepo.createExercise(exercise);
      }

      if (!mounted) return;

      Navigator.pop(context);
      widget.onExerciseCreated();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.exercise != null
              ? 'Exercise updated successfully'
              : 'Custom exercise created successfully'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error ${widget.exercise != null ? 'updating' : 'creating'} exercise: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
