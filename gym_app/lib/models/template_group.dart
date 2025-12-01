class TemplateGroup {
  final int? id;
  final String name;
  final int orderIndex;
  final DateTime createdAt;

  TemplateGroup({
    this.id,
    required this.name,
    required this.orderIndex,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory TemplateGroup.fromMap(Map<String, dynamic> map) {
    return TemplateGroup(
      id: map['id'] as int?,
      name: map['name'] as String,
      orderIndex: map['order_index'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'order_index': orderIndex,
      'created_at': createdAt.toIso8601String(),
    };
  }

  TemplateGroup copyWith({
    int? id,
    String? name,
    int? orderIndex,
    DateTime? createdAt,
  }) {
    return TemplateGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
