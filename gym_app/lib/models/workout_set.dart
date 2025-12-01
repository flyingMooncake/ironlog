class WorkoutSet {
  final int? id;
  final int sessionId;
  final int exerciseId;
  final int setOrder;
  final double? weight;
  final int? reps;
  final int? durationSeconds;
  final int? rpe;
  final bool isWarmup;
  final bool isDropSet;
  final String? supersetId;
  final String? notes;
  final DateTime completedAt;

  WorkoutSet({
    this.id,
    required this.sessionId,
    required this.exerciseId,
    required this.setOrder,
    this.weight,
    this.reps,
    this.durationSeconds,
    this.rpe,
    this.isWarmup = false,
    this.isDropSet = false,
    this.supersetId,
    this.notes,
    DateTime? completedAt,
  }) : completedAt = completedAt ?? DateTime.now();

  factory WorkoutSet.fromMap(Map<String, dynamic> map) {
    return WorkoutSet(
      id: map['id'] as int?,
      sessionId: map['session_id'] as int,
      exerciseId: map['exercise_id'] as int,
      setOrder: map['set_order'] as int,
      weight: map['weight'] as double?,
      reps: map['reps'] as int?,
      durationSeconds: map['duration_seconds'] as int?,
      rpe: map['rpe'] as int?,
      isWarmup: map['is_warmup'] == 1,
      isDropSet: (map['is_drop_set'] ?? 0) == 1,
      supersetId: map['superset_id'] as String?,
      notes: map['notes'] as String?,
      completedAt: DateTime.parse(map['completed_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'session_id': sessionId,
      'exercise_id': exerciseId,
      'set_order': setOrder,
      'weight': weight,
      'reps': reps,
      'duration_seconds': durationSeconds,
      'rpe': rpe,
      'is_warmup': isWarmup ? 1 : 0,
      'is_drop_set': isDropSet ? 1 : 0,
      'superset_id': supersetId,
      'notes': notes,
      'completed_at': completedAt.toIso8601String(),
    };
  }

  double get volume => (weight ?? 0) * (reps ?? 0);

  WorkoutSet copyWith({
    int? id,
    int? sessionId,
    int? exerciseId,
    int? setOrder,
    double? weight,
    int? reps,
    int? durationSeconds,
    int? rpe,
    bool? isWarmup,
    bool? isDropSet,
    String? supersetId,
    String? notes,
    DateTime? completedAt,
  }) {
    return WorkoutSet(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      exerciseId: exerciseId ?? this.exerciseId,
      setOrder: setOrder ?? this.setOrder,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      rpe: rpe ?? this.rpe,
      isWarmup: isWarmup ?? this.isWarmup,
      isDropSet: isDropSet ?? this.isDropSet,
      supersetId: supersetId ?? this.supersetId,
      notes: notes ?? this.notes,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
