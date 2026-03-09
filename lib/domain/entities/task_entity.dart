class TaskEntity {
  final int? id;
  final String title;
  final String? description;
  final String? project;
  final String? labelsCsv;
  final int priority;
  final DateTime? dueDate;
  final DateTime? reminderAt;
  final bool isRecurring;
  final String? recurrenceRule;
  final DateTime? completedAt;
  final bool isCompleted;
  final DateTime createdAt;

  const TaskEntity({
    this.id,
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
    this.isCompleted = false,
    required this.createdAt,
  });

  TaskEntity copyWith({
    int? id,
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
    return TaskEntity(
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

  List<String> get labels {
    if (labelsCsv == null) return const <String>[];
    return labelsCsv!
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  DateTime? get normalizedDueDate =>
      dueDate == null
          ? null
          : DateTime(dueDate!.year, dueDate!.month, dueDate!.day, dueDate!.hour, dueDate!.minute);

  bool get hasDueDate =>
      dueDate != null;
}
