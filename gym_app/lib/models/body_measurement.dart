class BodyMeasurement {
  final int? id;
  final double? chest;
  final double? waist;
  final double? hips;
  final double? leftArm;
  final double? rightArm;
  final double? leftThigh;
  final double? rightThigh;
  final double? leftCalf;
  final double? rightCalf;
  final double? shoulders;
  final double? neck;
  final String? notes;
  final DateTime recordedAt;

  BodyMeasurement({
    this.id,
    this.chest,
    this.waist,
    this.hips,
    this.leftArm,
    this.rightArm,
    this.leftThigh,
    this.rightThigh,
    this.leftCalf,
    this.rightCalf,
    this.shoulders,
    this.neck,
    this.notes,
    DateTime? recordedAt,
  }) : recordedAt = recordedAt ?? DateTime.now();

  factory BodyMeasurement.fromMap(Map<String, dynamic> map) {
    return BodyMeasurement(
      id: map['id'] as int?,
      chest: (map['chest'] as num?)?.toDouble(),
      waist: (map['waist'] as num?)?.toDouble(),
      hips: (map['hips'] as num?)?.toDouble(),
      leftArm: (map['left_arm'] as num?)?.toDouble(),
      rightArm: (map['right_arm'] as num?)?.toDouble(),
      leftThigh: (map['left_thigh'] as num?)?.toDouble(),
      rightThigh: (map['right_thigh'] as num?)?.toDouble(),
      leftCalf: (map['left_calf'] as num?)?.toDouble(),
      rightCalf: (map['right_calf'] as num?)?.toDouble(),
      shoulders: (map['shoulders'] as num?)?.toDouble(),
      neck: (map['neck'] as num?)?.toDouble(),
      notes: map['notes'] as String?,
      recordedAt: DateTime.parse(map['recorded_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'chest': chest,
      'waist': waist,
      'hips': hips,
      'left_arm': leftArm,
      'right_arm': rightArm,
      'left_thigh': leftThigh,
      'right_thigh': rightThigh,
      'left_calf': leftCalf,
      'right_calf': rightCalf,
      'shoulders': shoulders,
      'neck': neck,
      'notes': notes,
      'recorded_at': recordedAt.toIso8601String(),
    };
  }
}
