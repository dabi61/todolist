class ProjectEntity {
  final int? id;
  final String name;
  final int color;
  final bool isArchived;
  final DateTime createdAt;

  const ProjectEntity({
    this.id,
    required this.name,
    this.color = 0xFF6750A4,
    this.isArchived = false,
    required this.createdAt,
  });

  ProjectEntity copyWith({
    int? id,
    String? name,
    int? color,
    bool? isArchived,
    DateTime? createdAt,
  }) {
    return ProjectEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
