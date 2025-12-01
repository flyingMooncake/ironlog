import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/colors.dart';
import '../../models/personal_record.dart';
import '../../repositories/personal_record_repository.dart';

class PersonalRecordsScreen extends StatefulWidget {
  const PersonalRecordsScreen({super.key});

  @override
  State<PersonalRecordsScreen> createState() => _PersonalRecordsScreenState();
}

class _PersonalRecordsScreenState extends State<PersonalRecordsScreen> {
  final PersonalRecordRepository _prRepo = PersonalRecordRepository();
  List<PersonalRecord> _prs = [];
  bool _isLoading = true;
  String _filterType = 'all';

  @override
  void initState() {
    super.initState();
    _loadPRs();
  }

  Future<void> _loadPRs() async {
    setState(() => _isLoading = true);
    final prs = await _prRepo.getAllPRs();
    setState(() {
      _prs = prs;
      _isLoading = false;
    });
  }

  List<PersonalRecord> get _filteredPRs {
    if (_filterType == 'all') return _prs;
    return _prs.where((pr) => pr.recordType == _filterType).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Personal Records'),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _filteredPRs.isEmpty
                    ? _buildEmptyState()
                    : _buildPRList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = {
      'all': 'All',
      '1rm': 'Est. 1RM',
      'max_weight': 'Max Weight',
      'max_reps': 'Max Reps',
      'max_volume': 'Max Volume',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.entries.map((entry) {
            final isSelected = _filterType == entry.key;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(entry.value),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _filterType = entry.key);
                },
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surface,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events,
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Personal Records Yet',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Complete workouts to start tracking PRs',
            style: TextStyle(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPRList() {
    // Group PRs by exercise
    final Map<String, List<PersonalRecord>> groupedPRs = {};
    for (final pr in _filteredPRs) {
      if (!groupedPRs.containsKey(pr.exerciseName)) {
        groupedPRs[pr.exerciseName] = [];
      }
      groupedPRs[pr.exerciseName]!.add(pr);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedPRs.length,
      itemBuilder: (context, index) {
        final exerciseName = groupedPRs.keys.elementAt(index);
        final exercisePRs = groupedPRs[exerciseName]!;
        return _buildExercisePRCard(exerciseName, exercisePRs);
      },
    );
  }

  Widget _buildExercisePRCard(String exerciseName, List<PersonalRecord> prs) {
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
                const Icon(
                  Icons.emoji_events,
                  color: AppColors.warning,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    exerciseName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.surfaceHighlight, height: 1),
          ...prs.map((pr) => _buildPRRow(pr)),
        ],
      ),
    );
  }

  Widget _buildPRRow(PersonalRecord pr) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceHighlight, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getRecordTypeColor(pr.recordType).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                _getRecordTypeIcon(pr.recordType),
                color: _getRecordTypeColor(pr.recordType),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getRecordTypeLabel(pr.recordType),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatPRValue(pr),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(pr.achievedAt),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getRecordTypeLabel(String type) {
    switch (type) {
      case '1rm':
        return 'Estimated 1RM';
      case 'max_weight':
        return 'Max Weight';
      case 'max_reps':
        return 'Max Reps';
      case 'max_volume':
        return 'Max Volume';
      default:
        return type;
    }
  }

  IconData _getRecordTypeIcon(String type) {
    switch (type) {
      case '1rm':
        return Icons.trending_up;
      case 'max_weight':
        return Icons.fitness_center;
      case 'max_reps':
        return Icons.repeat;
      case 'max_volume':
        return Icons.analytics;
      default:
        return Icons.star;
    }
  }

  Color _getRecordTypeColor(String type) {
    switch (type) {
      case '1rm':
        return AppColors.primary;
      case 'max_weight':
        return AppColors.success;
      case 'max_reps':
        return AppColors.warning;
      case 'max_volume':
        return AppColors.info;
      default:
        return AppColors.textMuted;
    }
  }

  String _formatPRValue(PersonalRecord pr) {
    switch (pr.recordType) {
      case '1rm':
        return '${pr.value.toStringAsFixed(1)} kg';
      case 'max_weight':
        return '${pr.weight!.toStringAsFixed(1)} kg × ${pr.reps} reps';
      case 'max_reps':
        return '${pr.reps} reps @ ${pr.weight!.toStringAsFixed(1)} kg';
      case 'max_volume':
        return '${pr.value.toStringAsFixed(0)} kg (${pr.weight!.toStringAsFixed(1)} kg × ${pr.reps})';
      default:
        return pr.value.toStringAsFixed(1);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }
}
