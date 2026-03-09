class LabelEntity {
  final int? id;
  final String name;
  final int color;
  final bool isArchived;
  final DateTime createdAt;

  const LabelEntity({
    this.id,
    required this.name,
    this.color = 0xFF1E88E5,
    this.isArchived = false,
    required this.createdAt,
  });

  LabelEntity copyWith({
    int? id,
    String? name,
    int? color,
    bool? isArchived,
    DateTime? createdAt,
  }) {
    return LabelEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
