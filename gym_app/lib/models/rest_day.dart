class RestDay {
  final int? id;
  final DateTime restDate;
  final bool isPlanned;
  final String? notes;
  final DateTime createdAt;

  RestDay({
    this.id,
    required this.restDate,
    this.isPlanned = true,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory RestDay.fromMap(Map<String, dynamic> map) {
    return RestDay(
      id: map['id'] as int?,
      restDate: DateTime.parse(map['rest_date'] as String),
      isPlanned: map['is_planned'] == 1,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'rest_date': restDate.toIso8601String(),
      'is_planned': isPlanned ? 1 : 0,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  RestDay copyWith({
    int? id,
    DateTime? restDate,
    bool? isPlanned,
    String? notes,
    DateTime? createdAt,
  }) {
    return RestDay(
      id: id ?? this.id,
      restDate: restDate ?? this.restDate,
      isPlanned: isPlanned ?? this.isPlanned,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper to get just the date part for comparison
  DateTime get dateOnly {
    return DateTime(restDate.year, restDate.month, restDate.day);
  }
}
