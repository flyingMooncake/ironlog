enum PhotoType {
  front,
  side,
  back,
  custom;

  String get displayName {
    switch (this) {
      case PhotoType.front:
        return 'Front';
      case PhotoType.side:
        return 'Side';
      case PhotoType.back:
        return 'Back';
      case PhotoType.custom:
        return 'Custom';
    }
  }
}

class ProgressPhoto {
  final int? id;
  final String filePath;
  final double? weight;
  final String? notes;
  final PhotoType photoType;
  final DateTime takenAt;

  ProgressPhoto({
    this.id,
    required this.filePath,
    this.weight,
    this.notes,
    this.photoType = PhotoType.front,
    DateTime? takenAt,
  }) : takenAt = takenAt ?? DateTime.now();

  factory ProgressPhoto.fromMap(Map<String, dynamic> map) {
    return ProgressPhoto(
      id: map['id'] as int?,
      filePath: map['file_path'] as String,
      weight: map['weight'] as double?,
      notes: map['notes'] as String?,
      photoType: PhotoType.values.firstWhere(
        (e) => e.name == map['photo_type'],
        orElse: () => PhotoType.front,
      ),
      takenAt: DateTime.parse(map['taken_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'file_path': filePath,
      'weight': weight,
      'notes': notes,
      'photo_type': photoType.name,
      'taken_at': takenAt.toIso8601String(),
    };
  }

  ProgressPhoto copyWith({
    int? id,
    String? filePath,
    double? weight,
    String? notes,
    PhotoType? photoType,
    DateTime? takenAt,
  }) {
    return ProgressPhoto(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      weight: weight ?? this.weight,
      notes: notes ?? this.notes,
      photoType: photoType ?? this.photoType,
      takenAt: takenAt ?? this.takenAt,
    );
  }
}
