import 'package:isar/isar.dart';
import 'package:todo_list_flutter/domain/entities/label_entity.dart';

part 'label.g.dart';

@Collection()
class Label {
  Id id = Isar.autoIncrement;

  late String name;

  int color = 0xFF1E88E5;

  bool isArchived = false;

  late DateTime createdAt;

  Label();

  Label.create({
    required this.name,
    this.color = 0xFF1E88E5,
    this.isArchived = false,
    required this.createdAt,
    Id? id,
  }) {
    this.id = id ?? Isar.autoIncrement;
  }

  LabelEntity toEntity() {
    return LabelEntity(
      id: id == Isar.autoIncrement ? null : id,
      name: name,
      color: color,
      isArchived: isArchived,
      createdAt: createdAt,
    );
  }

  Label copyWith({
    Id? id,
    String? name,
    int? color,
    bool? isArchived,
    DateTime? createdAt,
  }) {
    return Label.create(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static Label fromEntity(LabelEntity entity) {
    return Label.create(
      id: entity.id,
      name: entity.name,
      color: entity.color,
      isArchived: entity.isArchived,
      createdAt: entity.createdAt,
    );
  }
}
