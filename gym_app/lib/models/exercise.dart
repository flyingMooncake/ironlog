enum MuscleGroup {
  chest,
  back,
  shoulders,
  biceps,
  triceps,
  forearms,
  quads,
  hamstrings,
  glutes,
  calves,
  abs,
  obliques,
  lowerBack,
  traps,
  lats,
  fullBody,
  cardio;

  String get displayName {
    switch (this) {
      case MuscleGroup.lowerBack:
        return 'Lower Back';
      case MuscleGroup.fullBody:
        return 'Full Body';
      default:
        return name[0].toUpperCase() + name.substring(1);
    }
  }
}

enum TrackingType {
  weightReps, // Bench press, squat
  repsOnly, // Pull-ups (bodyweight)
  time, // Plank, wall sit
  weightTime, // Farmer walks
  assistedWeightReps; // Assisted pull-ups, assisted dips (negative weight)

  String get displayName {
    switch (this) {
      case TrackingType.weightReps:
        return 'Weight & Reps';
      case TrackingType.repsOnly:
        return 'Reps Only';
      case TrackingType.time:
        return 'Time';
      case TrackingType.weightTime:
        return 'Weight & Time';
      case TrackingType.assistedWeightReps:
        return 'Assisted (Negative Weight)';
    }
  }
}

enum Equipment {
  barbell,
  dumbbell,
  cable,
  machine,
  bodyweight,
  kettlebell,
  bands,
  other;

  String get displayName => name[0].toUpperCase() + name.substring(1);
}

class Exercise {
  final int? id;
  final String name;
  final MuscleGroup primaryMuscle;
  final List<MuscleGroup> secondaryMuscles;
  final TrackingType trackingType;
  final Equipment? equipment;
  final bool isCustom;
  final String? notes;
  final DateTime createdAt;

  Exercise({
    this.id,
    required this.name,
    required this.primaryMuscle,
    this.secondaryMuscles = const [],
    this.trackingType = TrackingType.weightReps,
    this.equipment,
    this.isCustom = false,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'] as int?,
      name: map['name'] as String,
      primaryMuscle: MuscleGroup.values.firstWhere(
        (e) => e.name == map['primary_muscle'],
        orElse: () => MuscleGroup.fullBody,
      ),
      secondaryMuscles: (map['secondary_muscles'] as String?)
              ?.split(',')
              .where((s) => s.isNotEmpty)
              .map((s) => MuscleGroup.values.firstWhere(
                    (e) => e.name == s.trim(),
                    orElse: () => MuscleGroup.fullBody,
                  ))
              .toList() ??
          [],
      trackingType: TrackingType.values.firstWhere(
        (e) => e.name == _snakeToCamel(map['tracking_type'] ?? 'weight_reps'),
        orElse: () => TrackingType.weightReps,
      ),
      equipment: map['equipment'] != null
          ? Equipment.values.firstWhere(
              (e) => e.name == map['equipment'],
              orElse: () => Equipment.other,
            )
          : null,
      isCustom: map['is_custom'] == 1,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'primary_muscle': primaryMuscle.name,
      'secondary_muscles': secondaryMuscles.map((e) => e.name).join(','),
      'tracking_type': _camelToSnake(trackingType.name),
      'equipment': equipment?.name,
      'is_custom': isCustom ? 1 : 0,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static String _snakeToCamel(String s) {
    return s.replaceAllMapped(
      RegExp(r'_([a-z])'),
      (m) => m.group(1)!.toUpperCase(),
    );
  }

  static String _camelToSnake(String s) {
    return s.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (m) => '_${m.group(0)!.toLowerCase()}',
    );
  }
}
