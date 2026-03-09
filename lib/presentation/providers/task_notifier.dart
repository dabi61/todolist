import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:todo_list_flutter/core/providers/app_providers.dart';
import 'package:todo_list_flutter/domain/entities/task_entity.dart';

part 'task_notifier.g.dart';

@Riverpod(keepAlive: true)
class TaskNotifier extends _$TaskNotifier {
  @override
  Future<List<TaskEntity>> build() async {
    return ref.read(taskRepositoryProvider).getTasks();
  }

  Future<void> saveTask({
    TaskEntity? editingTask,
    required String title,
    String? description,
    String? project,
    List<String>? labels,
    int priority = 0,
    DateTime? dueDate,
    DateTime? reminderAt,
    bool isRecurring = false,
    String? recurrenceRule,
  }) async {
    if (editingTask == null) {
      await addNewTask(
        title: title,
        description: description,
        project: project,
        labels: labels,
        priority: priority,
        dueDate: dueDate,
        reminderAt: reminderAt,
        isRecurring: isRecurring,
        recurrenceRule: recurrenceRule,
      );
      return;
    }

    final normalized = _normalizeTaskInputs(
      title: title,
      description: description,
      project: project,
      labels: labels,
      priority: priority,
      dueDate: dueDate,
      reminderAt: reminderAt,
      isRecurring: isRecurring,
      recurrenceRule: recurrenceRule,
      completedAt: editingTask.completedAt,
      isCompleted: editingTask.isCompleted,
      createdAt: editingTask.createdAt,
    );

    if (normalized.title.isEmpty) return;

    final updatedTask = editingTask.copyWith(
      title: normalized.title,
      description: normalized.description,
      project: normalized.project,
      labelsCsv: normalized.labelsCsv,
      priority: normalized.priority,
      dueDate: normalized.dueDate,
      reminderAt: normalized.reminderAt,
      isRecurring: normalized.isRecurring,
      recurrenceRule: normalized.recurrenceRule,
      isCompleted: normalized.isCompleted,
      completedAt: normalized.completedAt,
      createdAt: normalized.createdAt,
    );

    await updateTask(updatedTask);
  }

  Future<void> addNewTask({
    required String title,
    String? description,
    String? project,
    List<String>? labels,
    int priority = 0,
    DateTime? dueDate,
    DateTime? reminderAt,
    bool isRecurring = false,
    String? recurrenceRule,
  }) async {
    final normalized = _normalizeTaskInputs(
      title: title,
      description: description,
      project: project,
      labels: labels,
      priority: priority,
      dueDate: dueDate,
      reminderAt: reminderAt,
      isRecurring: isRecurring,
      recurrenceRule: recurrenceRule,
      createdAt: DateTime.now(),
    );

    if (normalized.title.isEmpty) return;

    final repository = ref.read(taskRepositoryProvider);
    final List<TaskEntity> previous = [...(state.valueOrNull ?? const <TaskEntity>[])];

    try {
      await _ensureMetadata(
        project: normalized.project,
        labels: _toLabelList(normalized.labelsCsv),
      );

      final createdTask = TaskEntity(
        title: normalized.title,
        description: normalized.description,
        project: normalized.project,
        labelsCsv: normalized.labelsCsv,
        priority: normalized.priority,
        dueDate: normalized.dueDate,
        reminderAt: normalized.reminderAt,
        isRecurring: normalized.isRecurring,
        recurrenceRule: normalized.recurrenceRule,
        isCompleted: false,
        completedAt: null,
        createdAt: normalized.createdAt,
      );

      final savedTask = await repository.addTask(createdTask);
      final nextState = [...previous, savedTask];
      state = AsyncData(_sortTasks(nextState));
    } catch (error, stackTrace) {
      final repositoryTasks = await _reloadFromRepository();
      state = AsyncData(repositoryTasks);
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> toggleTaskCompletion(TaskEntity task) async {
    if (task.id == null) return;

    final repository = ref.read(taskRepositoryProvider);
    final List<TaskEntity> current = [...(state.valueOrNull ?? const <TaskEntity>[])];

    final index = current.indexWhere((item) => item.id == task.id);
    if (index == -1) return;

    final nextCompleted = !task.isCompleted;
    final updatedTask = task.copyWith(
      isCompleted: nextCompleted,
      completedAt: nextCompleted ? DateTime.now() : null,
    );
    current[index] = updatedTask;
    state = AsyncData(_sortTasks(current));

    try {
      await repository.updateTask(updatedTask);
      final updatedState = [...(state.valueOrNull ?? const <TaskEntity>[])];
      final updatedIndex = updatedState.indexWhere((item) => item.id == task.id);
      if (updatedIndex != -1) {
        updatedState[updatedIndex] = updatedTask;
      } else {
        updatedState.add(updatedTask);
      }
      state = AsyncData(_sortTasks(updatedState));

      if (nextCompleted &&
          updatedTask.isRecurring &&
          updatedTask.dueDate != null &&
          updatedTask.recurrenceRule != null) {
        final nextDueDate = _computeNextRecurringDate(updatedTask.dueDate!, updatedTask.recurrenceRule);
        if (nextDueDate != null) {
          final nextTask = updatedTask.copyWith(
            id: null,
            isCompleted: false,
            completedAt: null,
            dueDate: nextDueDate,
            createdAt: DateTime.now(),
          );
          final generatedTask = await repository.addTask(nextTask);
          final recurringState = [...(state.valueOrNull ?? const <TaskEntity>[]), generatedTask];
          state = AsyncData(_sortTasks(recurringState));
        }
      }
    } catch (error, stackTrace) {
      final repositoryTasks = await _reloadFromRepository();
      state = AsyncData(repositoryTasks);
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> removeTask(int id) async {
    final repository = ref.read(taskRepositoryProvider);
    final List<TaskEntity> current = [...(state.valueOrNull ?? const <TaskEntity>[])]
      ..removeWhere((task) => task.id == id);

    state = AsyncData(_sortTasks(current));

    try {
      await repository.deleteTask(id);
    } catch (error, stackTrace) {
      final repositoryTasks = await _reloadFromRepository();
      state = AsyncData(repositoryTasks);
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> updateTask(TaskEntity task) async {
    final id = task.id;
    if (id == null) return;

    final repository = ref.read(taskRepositoryProvider);
    final List<TaskEntity> current = [...(state.valueOrNull ?? const <TaskEntity>[])];
    final index = current.indexWhere((item) => item.id == id);
    if (index == -1) return;

    final normalized = _normalizeTaskInputs(
      title: task.title,
      description: task.description,
      project: task.project,
      labels: task.labels,
      priority: task.priority,
      dueDate: task.dueDate,
      reminderAt: task.reminderAt,
      isRecurring: task.isRecurring,
      recurrenceRule: task.recurrenceRule,
      isCompleted: task.isCompleted,
      completedAt: task.completedAt,
      createdAt: task.createdAt,
    );

    final updatedTask = task.copyWith(
      title: normalized.title,
      description: normalized.description,
      project: normalized.project,
      labelsCsv: normalized.labelsCsv,
      priority: normalized.priority,
      dueDate: normalized.dueDate,
      reminderAt: normalized.reminderAt,
      isRecurring: normalized.isRecurring,
      recurrenceRule: normalized.recurrenceRule,
      isCompleted: normalized.isCompleted,
      completedAt: normalized.completedAt,
      createdAt: normalized.createdAt,
    );

    final optimistic = [...current];
    optimistic[index] = updatedTask;
    state = AsyncData(_sortTasks(optimistic));

    try {
      await _ensureMetadata(
        project: normalized.project,
        labels: _toLabelList(normalized.labelsCsv),
      );

      final saved = await repository.updateTask(updatedTask);
      final savedList = [...(state.valueOrNull ?? const <TaskEntity>[])];
      final savedIndex = savedList.indexWhere((item) => item.id == id);
      if (savedIndex != -1) {
        savedList[savedIndex] = saved;
      }
      state = AsyncData(_sortTasks(savedList));
    } catch (error, stackTrace) {
      final repositoryTasks = await _reloadFromRepository();
      state = AsyncData(repositoryTasks);
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> bulkSetCompletion(Set<int> ids, bool isCompleted) async {
    if (ids.isEmpty) return;

    final repository = ref.read(taskRepositoryProvider);
    final current = [...(state.valueOrNull ?? const <TaskEntity>[])];

    final now = DateTime.now();
    final updatedList = <TaskEntity>[];

    for (final task in current) {
      if (task.id == null || !ids.contains(task.id)) {
        updatedList.add(task);
        continue;
      }

      updatedList.add(task.copyWith(
        isCompleted: isCompleted,
        completedAt: isCompleted ? now : null,
      ));
    }

    state = AsyncData(_sortTasks(updatedList));

    try {
      for (final task in updatedList) {
        if (task.id == null) continue;
        if (!ids.contains(task.id)) continue;

        await repository.updateTask(task);
      }
    } catch (error, stackTrace) {
      final repositoryTasks = await _reloadFromRepository();
      state = AsyncData(repositoryTasks);
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> deleteTasks(Set<int> ids) async {
    if (ids.isEmpty) return;

    final repository = ref.read(taskRepositoryProvider);
    final current = [...(state.valueOrNull ?? const <TaskEntity>[])];

    final remaining = current.where((task) => task.id == null || !ids.contains(task.id)).toList();
    state = AsyncData(_sortTasks(remaining));

    try {
      for (final id in ids) {
        await repository.deleteTask(id);
      }
    } catch (error, stackTrace) {
      final repositoryTasks = await _reloadFromRepository();
      state = AsyncData(repositoryTasks);
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> moveTasksToProject(Set<int> ids, String? project) async {
    if (ids.isEmpty) return;

    final repository = ref.read(taskRepositoryProvider);
    final current = [...(state.valueOrNull ?? const <TaskEntity>[])];
    final normalizedProject =
        (project == null || project.trim().isEmpty) ? 'Inbox' : project.trim();

    await _ensureMetadata(project: normalizedProject, labels: const <String>[]);

    final updatedList = [...current];
    for (var i = 0; i < updatedList.length; i++) {
      final task = updatedList[i];
      if (task.id == null || !ids.contains(task.id)) continue;
      updatedList[i] = task.copyWith(project: normalizedProject);
    }

    state = AsyncData(_sortTasks(updatedList));

    try {
      for (final task in updatedList) {
        if (task.id == null || !ids.contains(task.id)) continue;

        await repository.updateTask(task);
      }
    } catch (error, stackTrace) {
      final repositoryTasks = await _reloadFromRepository();
      state = AsyncData(repositoryTasks);
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> setLabelsForTasks(Set<int> ids, List<String> labels) async {
    if (ids.isEmpty) return;

    final normalizedLabels = labels
        .map((label) => label.trim())
        .where((label) => label.isNotEmpty)
        .toList();

    await _ensureMetadata(project: null, labels: normalizedLabels);

    final repository = ref.read(taskRepositoryProvider);
    final labelsCsv = normalizedLabels.isEmpty ? null : normalizedLabels.join(',');

    final current = [...(state.valueOrNull ?? const <TaskEntity>[])];
    final updatedList = <TaskEntity>[];

    for (final task in current) {
      if (task.id != null && ids.contains(task.id)) {
        updatedList.add(task.copyWith(labelsCsv: labelsCsv));
      } else {
        updatedList.add(task);
      }
    }

    state = AsyncData(_sortTasks(updatedList));

    try {
      for (final task in updatedList) {
        if (task.id == null || !ids.contains(task.id)) continue;

        await repository.updateTask(task);
      }
    } catch (error, stackTrace) {
      final repositoryTasks = await _reloadFromRepository();
      state = AsyncData(repositoryTasks);
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> clearCompletedTasks() async {
    final repository = ref.read(taskRepositoryProvider);
    final completed =
        (state.valueOrNull ?? const <TaskEntity>[]).where((task) => task.isCompleted).toList();

    if (completed.isEmpty) return;

    final updatedList = [
      for (final task in state.valueOrNull ?? const <TaskEntity>[])
        if (!task.isCompleted) task,
    ];
    state = AsyncData(_sortTasks(updatedList));

    try {
      for (final task in completed) {
        if (task.id != null) {
          await repository.deleteTask(task.id!);
        }
      }
    } catch (error, stackTrace) {
      final repositoryTasks = await _reloadFromRepository();
      state = AsyncData(repositoryTasks);
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final tasks = await _reloadFromRepository();
      state = AsyncData(tasks);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<List<TaskEntity>> _reloadFromRepository() async {
    try {
      final repository = ref.read(taskRepositoryProvider);
      final tasks = await repository.getTasks();
      return _sortTasks(tasks);
    } catch (_) {
      return state.valueOrNull ?? const <TaskEntity>[];
    }
  }

  Future<void> _ensureMetadata({
    required String? project,
    required List<String> labels,
  }) async {
    if ((project?.trim() ?? '').isNotEmpty) {
      await ref.read(projectRepositoryProvider).upsertProjectByName(project!);
    }

    for (final label in labels) {
      final normalizedLabel = label.trim();
      if (normalizedLabel.isEmpty) continue;
      await ref.read(labelRepositoryProvider).upsertLabelByName(normalizedLabel);
    }
  }

  List<TaskEntity> _sortTasks(List<TaskEntity> tasks) {
    final sorted = List<TaskEntity>.from(tasks);
    sorted.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      if (a.dueDate != null && b.dueDate != null) {
        final dueCompare = a.dueDate!.compareTo(b.dueDate!);
        if (dueCompare != 0) return dueCompare;
      } else if (a.dueDate != null) {
        return -1;
      } else if (b.dueDate != null) {
        return 1;
      }

      if (a.priority != b.priority) return b.priority.compareTo(a.priority);

      return b.createdAt.compareTo(a.createdAt);
    });

    return sorted;
  }

  DateTime? _computeNextRecurringDate(DateTime dueDate, String? recurrenceRule) {
    final rule = recurrenceRule?.trim().toLowerCase();
    if (rule == null || rule.trim().isEmpty) return null;

    final interval = int.tryParse(RegExp(r'(\d+)').firstMatch(rule)?.group(1) ?? '1') ?? 1;
    final safeInterval = interval < 1 ? 1 : interval;

    if (rule.contains('week') && !rule.contains('weekday')) {
      return dueDate.add(Duration(days: 7 * safeInterval));
    }
    if (rule.contains('month')) {
      return _addMonths(dueDate, safeInterval);
    }
    if (rule.contains('year')) {
      return _addYears(dueDate, safeInterval);
    }
    if (rule.contains('weekday')) {
      return _nextWeekday(dueDate, safeInterval);
    }

    return dueDate.add(Duration(days: safeInterval));
  }

  DateTime _nextWeekday(DateTime date, int every) {
    var next = date;
    var remaining = every;
    while (remaining > 0) {
      next = next.add(const Duration(days: 1));
      if (next.weekday <= DateTime.friday) {
        remaining -= 1;
      }
    }
    return next;
  }

  DateTime _addMonths(DateTime date, int monthsToAdd) {
    final totalMonths = date.month - 1 + monthsToAdd;
    final targetYear = date.year + (totalMonths ~/ 12);
    final targetMonth = (totalMonths % 12) + 1;
    final maxDay = DateTime(targetYear, targetMonth + 1, 0).day;
    final day = date.day > maxDay ? maxDay : date.day;
    return DateTime(
      targetYear,
      targetMonth,
      day,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }

  DateTime _addYears(DateTime date, int yearsToAdd) {
    final targetYear = date.year + yearsToAdd;
    final maxDay = DateTime(targetYear, date.month + 1, 0).day;
    final day = date.day > maxDay ? maxDay : date.day;
    return DateTime(
      targetYear,
      date.month,
      day,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }

  _NormalizedTaskInput _normalizeTaskInputs({
    required String title,
    String? description,
    String? project,
    List<String>? labels,
    int priority = 0,
    DateTime? dueDate,
    DateTime? reminderAt,
    bool isRecurring = false,
    String? recurrenceRule,
    DateTime? completedAt,
    bool isCompleted = false,
    required DateTime createdAt,
  }) {
    final normalizedTitle = title.trim();
    final normalizedDescription =
        description == null || description.trim().isEmpty ? null : description.trim();
    final normalizedProject = project == null || project.trim().isEmpty ? 'Inbox' : project.trim();
    final normalizedLabels = labels
            ?.map((label) => label.trim())
            .where((label) => label.isNotEmpty)
            .toList() ??
        const <String>[];

    return _NormalizedTaskInput(
      title: normalizedTitle,
      description: normalizedDescription,
      project: normalizedProject,
      labelsCsv: normalizedLabels.isEmpty ? null : normalizedLabels.join(','),
      priority: priority,
      dueDate: dueDate,
      reminderAt: reminderAt,
      isRecurring: isRecurring,
      recurrenceRule: isRecurring ? recurrenceRule : null,
      isCompleted: isCompleted,
      completedAt: completedAt,
      createdAt: createdAt,
    );
  }

  List<String> _toLabelList(String? labelsCsv) {
    if (labelsCsv == null || labelsCsv.trim().isEmpty) return const <String>[];

    return labelsCsv
        .split(',')
        .map((label) => label.trim())
        .where((label) => label.isNotEmpty)
        .toList();
  }
}

class _NormalizedTaskInput {
  const _NormalizedTaskInput({
    required this.title,
    required this.description,
    required this.project,
    required this.labelsCsv,
    required this.priority,
    required this.dueDate,
    required this.reminderAt,
    required this.isRecurring,
    required this.recurrenceRule,
    required this.isCompleted,
    required this.completedAt,
    required this.createdAt,
  });

  final String title;
  final String? description;
  final String project;
  final String? labelsCsv;
  final int priority;
  final DateTime? dueDate;
  final DateTime? reminderAt;
  final bool isRecurring;
  final String? recurrenceRule;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;
}
