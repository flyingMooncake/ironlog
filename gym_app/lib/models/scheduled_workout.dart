class ScheduledWorkout {
  final int? id;
  final int? templateId;
  final DateTime scheduledDate;
  final bool completed;
  final int? completedSessionId;
  final String? notes;
  final DateTime createdAt;

  ScheduledWorkout({
    this.id,
    this.templateId,
    required this.scheduledDate,
    this.completed = false,
    this.completedSessionId,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ScheduledWorkout.fromMap(Map<String, dynamic> map) {
    return ScheduledWorkout(
      id: map['id'] as int?,
      templateId: map['template_id'] as int?,
      scheduledDate: DateTime.parse(map['scheduled_date'] as String),
      completed: map['completed'] == 1,
      completedSessionId: map['completed_session_id'] as int?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'template_id': templateId,
      'scheduled_date': scheduledDate.toIso8601String(),
      'completed': completed ? 1 : 0,
      'completed_session_id': completedSessionId,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ScheduledWorkout copyWith({
    int? id,
    int? templateId,
    DateTime? scheduledDate,
    bool? completed,
    int? completedSessionId,
    String? notes,
    DateTime? createdAt,
  }) {
    return ScheduledWorkout(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      completed: completed ?? this.completed,
      completedSessionId: completedSessionId ?? this.completedSessionId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper to get just the date part for comparison
  DateTime get dateOnly {
    return DateTime(scheduledDate.year, scheduledDate.month, scheduledDate.day);
  }
}
