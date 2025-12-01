class WorkoutTemplate {
  final int? id;
  final String name;
  final String? description;
  final int? groupId;
  final int orderInGroup;
  final List<TemplateExercise> exercises;
  final DateTime createdAt;
  final DateTime? lastUsed;

  WorkoutTemplate({
    this.id,
    required this.name,
    this.description,
    this.groupId,
    this.orderInGroup = 0,
    required this.exercises,
    DateTime? createdAt,
    this.lastUsed,
  }) : createdAt = createdAt ?? DateTime.now();

  factory WorkoutTemplate.fromMap(Map<String, dynamic> map) {
    return WorkoutTemplate(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      groupId: map['group_id'] as int?,
      orderInGroup: map['order_in_group'] as int? ?? 0,
      exercises: [], // Will be loaded separately
      createdAt: DateTime.parse(map['created_at'] as String),
      lastUsed: map['last_used'] != null
          ? DateTime.parse(map['last_used'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'group_id': groupId,
      'order_in_group': orderInGroup,
      'created_at': createdAt.toIso8601String(),
      'last_used': lastUsed?.toIso8601String(),
    };
  }

  WorkoutTemplate copyWith({
    int? id,
    String? name,
    String? description,
    int? groupId,
    int? orderInGroup,
    List<TemplateExercise>? exercises,
    DateTime? createdAt,
    DateTime? lastUsed,
  }) {
    return WorkoutTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      groupId: groupId ?? this.groupId,
      orderInGroup: orderInGroup ?? this.orderInGroup,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt ?? this.createdAt,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }
}

class TemplateExercise {
  final int? id;
  final int templateId;
  final int exerciseId;
  final int orderIndex;
  final int sets;
  final int? targetReps;
  final double? targetWeight;
  final int? restSeconds;
  final String? notes;

  TemplateExercise({
    this.id,
    required this.templateId,
    required this.exerciseId,
    required this.orderIndex,
    required this.sets,
    this.targetReps,
    this.targetWeight,
    this.restSeconds,
    this.notes,
  });

  factory TemplateExercise.fromMap(Map<String, dynamic> map) {
    return TemplateExercise(
      id: map['id'] as int?,
      templateId: map['template_id'] as int,
      exerciseId: map['exercise_id'] as int,
      orderIndex: map['order_index'] as int,
      sets: map['sets'] as int,
      targetReps: map['target_reps'] as int?,
      targetWeight: (map['target_weight'] as num?)?.toDouble(),
      restSeconds: map['rest_seconds'] as int?,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'template_id': templateId,
      'exercise_id': exerciseId,
      'order_index': orderIndex,
      'sets': sets,
      'target_reps': targetReps,
      'target_weight': targetWeight,
      'rest_seconds': restSeconds,
      'notes': notes,
    };
  }

  TemplateExercise copyWith({
    int? id,
    int? templateId,
    int? exerciseId,
    int? orderIndex,
    int? sets,
    int? targetReps,
    double? targetWeight,
    int? restSeconds,
    String? notes,
  }) {
    return TemplateExercise(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      exerciseId: exerciseId ?? this.exerciseId,
      orderIndex: orderIndex ?? this.orderIndex,
      sets: sets ?? this.sets,
      targetReps: targetReps ?? this.targetReps,
      targetWeight: targetWeight ?? this.targetWeight,
      restSeconds: restSeconds ?? this.restSeconds,
      notes: notes ?? this.notes,
    );
  }
}
