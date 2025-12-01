enum UnitSystem { metric, imperial }

class UserProfile {
  final int? id;
  final double? weight;
  final double? height;
  final int? age;
  final UnitSystem unitSystem;
  final int restTimerDefault;
  final bool autoStartRestTimer;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    this.id,
    this.weight,
    this.height,
    this.age,
    this.unitSystem = UnitSystem.metric,
    this.restTimerDefault = 60,
    this.autoStartRestTimer = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as int?,
      weight: map['weight'] as double?,
      height: map['height'] as double?,
      age: map['age'] as int?,
      unitSystem: map['unit_system'] == 'imperial'
          ? UnitSystem.imperial
          : UnitSystem.metric,
      restTimerDefault: map['rest_timer_default'] as int? ?? 90,
      autoStartRestTimer: (map['auto_start_rest_timer'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'weight': weight,
      'height': height,
      'age': age,
      'unit_system': unitSystem.name,
      'rest_timer_default': restTimerDefault,
      'auto_start_rest_timer': autoStartRestTimer ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get weightUnit => unitSystem == UnitSystem.metric ? 'kg' : 'lbs';
  String get heightUnit => unitSystem == UnitSystem.metric ? 'cm' : 'in';
}
