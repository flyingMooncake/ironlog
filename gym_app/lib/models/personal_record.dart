class PersonalRecord {
  final int? id;
  final int exerciseId;
  final String exerciseName;
  final String recordType; // '1rm', 'max_weight', 'max_reps', 'max_volume'
  final double value;
  final double? weight;
  final int? reps;
  final int? setId;
  final DateTime achievedAt;

  PersonalRecord({
    this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.recordType,
    required this.value,
    this.weight,
    this.reps,
    this.setId,
    DateTime? achievedAt,
  }) : achievedAt = achievedAt ?? DateTime.now();

  factory PersonalRecord.fromMap(Map<String, dynamic> map) {
    return PersonalRecord(
      id: map['id'] as int?,
      exerciseId: map['exercise_id'] as int,
      exerciseName: map['exercise_name'] as String? ?? '',
      recordType: map['record_type'] as String,
      value: (map['value'] as num).toDouble(),
      weight: (map['weight'] as num?)?.toDouble(),
      reps: map['reps'] as int?,
      setId: map['set_id'] as int?,
      achievedAt: DateTime.parse(map['achieved_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'exercise_id': exerciseId,
      'record_type': recordType,
      'value': value,
      if (weight != null) 'weight': weight,
      if (reps != null) 'reps': reps,
      if (setId != null) 'set_id': setId,
      'achieved_at': achievedAt.toIso8601String(),
    };
  }

  // Calculate estimated 1RM using Brzycki formula
  static double calculate1RM(double weight, int reps) {
    if (reps == 1) return weight;
    return weight * (36 / (37 - reps));
  }
}
