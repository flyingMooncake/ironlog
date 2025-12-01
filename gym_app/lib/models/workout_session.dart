class WorkoutSession {
  final int? id;
  final String? name;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final int? durationMinutes;
  final double? totalVolume;
  final String? notes;
  final double? bodyweight;

  WorkoutSession({
    this.id,
    this.name,
    required this.startedAt,
    this.finishedAt,
    this.durationMinutes,
    this.totalVolume,
    this.notes,
    this.bodyweight,
  });

  factory WorkoutSession.fromMap(Map<String, dynamic> map) {
    return WorkoutSession(
      id: map['id'] as int?,
      name: map['name'] as String?,
      startedAt: DateTime.parse(map['started_at'] as String),
      finishedAt: map['finished_at'] != null
          ? DateTime.parse(map['finished_at'] as String)
          : null,
      durationMinutes: map['duration_minutes'] as int?,
      totalVolume: map['total_volume'] as double?,
      notes: map['notes'] as String?,
      bodyweight: map['bodyweight'] as double?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'started_at': startedAt.toIso8601String(),
      'finished_at': finishedAt?.toIso8601String(),
      'duration_minutes': durationMinutes,
      'total_volume': totalVolume,
      'notes': notes,
      'bodyweight': bodyweight,
    };
  }

  WorkoutSession copyWith({
    int? id,
    String? name,
    DateTime? startedAt,
    DateTime? finishedAt,
    int? durationMinutes,
    double? totalVolume,
    String? notes,
    double? bodyweight,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      name: name ?? this.name,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      totalVolume: totalVolume ?? this.totalVolume,
      notes: notes ?? this.notes,
      bodyweight: bodyweight ?? this.bodyweight,
    );
  }
}
