class WeightEntry {
  final int? id;
  final double weight;
  final DateTime recordedAt;

  WeightEntry({
    this.id,
    required this.weight,
    DateTime? recordedAt,
  }) : recordedAt = recordedAt ?? DateTime.now();

  factory WeightEntry.fromMap(Map<String, dynamic> map) {
    return WeightEntry(
      id: map['id'] as int?,
      weight: (map['weight'] as num).toDouble(),
      recordedAt: DateTime.parse(map['recorded_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'weight': weight,
      'recorded_at': recordedAt.toIso8601String(),
    };
  }

  WeightEntry copyWith({
    int? id,
    double? weight,
    DateTime? recordedAt,
  }) {
    return WeightEntry(
      id: id ?? this.id,
      weight: weight ?? this.weight,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }
}
