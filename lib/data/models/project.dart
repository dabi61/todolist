import 'package:isar/isar.dart';
import 'package:todo_list_flutter/domain/entities/project_entity.dart';

part 'project.g.dart';

@Collection()
class Project {
  Id id = Isar.autoIncrement;

  late String name;

  int color = 0xFF6750A4;

  bool isArchived = false;

  late DateTime createdAt;

  Project();

  Project.create({
    required this.name,
    this.color = 0xFF6750A4,
    this.isArchived = false,
    required this.createdAt,
    Id? id,
  }) {
    this.id = id ?? Isar.autoIncrement;
  }

  ProjectEntity toEntity() {
    return ProjectEntity(
      id: id == Isar.autoIncrement ? null : id,
      name: name,
      color: color,
      isArchived: isArchived,
      createdAt: createdAt,
    );
  }

  Project copyWith({
    Id? id,
    String? name,
    int? color,
    bool? isArchived,
    DateTime? createdAt,
  }) {
    return Project.create(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static Project fromEntity(ProjectEntity entity) {
    return Project.create(
      id: entity.id,
      name: entity.name,
      color: entity.color,
      isArchived: entity.isArchived,
      createdAt: entity.createdAt,
    );
  }
}
