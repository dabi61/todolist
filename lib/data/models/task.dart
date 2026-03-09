import 'package:isar/isar.dart';
import 'package:todo_list_flutter/domain/entities/task_entity.dart';

part 'task.g.dart';

@Collection()
class Task {
  Id id = Isar.autoIncrement;

  late String title;

  String? description;

  String? project;

  String? labelsCsv;

  int priority = 0;

  DateTime? dueDate;

  DateTime? reminderAt;

  bool isRecurring = false;

  String? recurrenceRule;

  DateTime? completedAt;

  bool isCompleted = false;

  late DateTime createdAt;

  Task();

  Task.create({
    required this.title,
    this.description,
    this.project,
    this.labelsCsv,
    this.priority = 0,
    this.dueDate,
    this.reminderAt,
    this.isRecurring = false,
    this.recurrenceRule,
    this.completedAt,
    required this.createdAt,
    this.isCompleted = false,
    Id? id,
  }) {
    this.id = id ?? Isar.autoIncrement;
  }

  TaskEntity toEntity() {
    return TaskEntity(
      id: id == Isar.autoIncrement ? null : id,
      title: title,
      description: description,
      project: project,
      labelsCsv: labelsCsv,
      priority: priority,
      dueDate: dueDate,
      reminderAt: reminderAt,
      isRecurring: isRecurring,
      recurrenceRule: recurrenceRule,
      completedAt: completedAt,
      isCompleted: isCompleted,
      createdAt: createdAt,
    );
  }

  Task copyWith({
    Id? id,
    String? title,
    String? description,
    String? project,
    String? labelsCsv,
    int? priority,
    DateTime? dueDate,
    DateTime? reminderAt,
    bool? isRecurring,
    String? recurrenceRule,
    DateTime? completedAt,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return Task.create(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      project: project ?? this.project,
      labelsCsv: labelsCsv ?? this.labelsCsv,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      reminderAt: reminderAt ?? this.reminderAt,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      completedAt: completedAt ?? this.completedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static Task fromEntity(TaskEntity entity) {
    return Task.create(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      project: entity.project,
      labelsCsv: entity.labelsCsv,
      priority: entity.priority,
      dueDate: entity.dueDate,
      reminderAt: entity.reminderAt,
      isRecurring: entity.isRecurring,
      recurrenceRule: entity.recurrenceRule,
      completedAt: entity.completedAt,
      isCompleted: entity.isCompleted,
      createdAt: entity.createdAt,
    );
  }
}
