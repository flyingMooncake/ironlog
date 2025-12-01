enum TargetType {
  weight,    // Target weight for an exercise
  reps,      // Target reps at a certain weight
  oneRM,     // Target 1RM
  volume,    // Target total volume per workout
  frequency; // Target frequency per week

  String get displayName {
    switch (this) {
      case TargetType.weight:
        return 'Weight';
      case TargetType.reps:
        return 'Reps';
      case TargetType.oneRM:
        return '1RM';
      case TargetType.volume:
        return 'Volume';
      case TargetType.frequency:
        return 'Frequency';
    }
  }
}

class ExerciseTarget {
  final int? id;
  final int exerciseId;
  final TargetType targetType;
  final double targetValue;
  final double currentValue;
  final DateTime? deadline;
  final DateTime? achievedAt;
  final DateTime createdAt;

  ExerciseTarget({
    this.id,
    required this.exerciseId,
    required this.targetType,
    required this.targetValue,
    this.currentValue = 0,
    this.deadline,
    this.achievedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ExerciseTarget.fromMap(Map<String, dynamic> map) {
    return ExerciseTarget(
      id: map['id'] as int?,
      exerciseId: map['exercise_id'] as int,
      targetType: TargetType.values.firstWhere(
        (e) => e.name == map['target_type'],
        orElse: () => TargetType.weight,
      ),
      targetValue: (map['target_value'] as num).toDouble(),
      currentValue: (map['current_value'] as num?)?.toDouble() ?? 0,
      deadline: map['deadline'] != null
          ? DateTime.parse(map['deadline'] as String)
          : null,
      achievedAt: map['achieved_at'] != null
          ? DateTime.parse(map['achieved_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'exercise_id': exerciseId,
      'target_type': targetType.name,
      'target_value': targetValue,
      'current_value': currentValue,
      'deadline': deadline?.toIso8601String(),
      'achieved_at': achievedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  ExerciseTarget copyWith({
    int? id,
    int? exerciseId,
    TargetType? targetType,
    double? targetValue,
    double? currentValue,
    DateTime? deadline,
    DateTime? achievedAt,
    DateTime? createdAt,
  }) {
    return ExerciseTarget(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      targetType: targetType ?? this.targetType,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      deadline: deadline ?? this.deadline,
      achievedAt: achievedAt ?? this.achievedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isAchieved => achievedAt != null || currentValue >= targetValue;

  double get progressPercentage {
    if (targetValue == 0) return 0;
    return (currentValue / targetValue * 100).clamp(0, 100);
  }

  bool get isOverdue {
    if (deadline == null || isAchieved) return false;
    return DateTime.now().isAfter(deadline!);
  }
}
