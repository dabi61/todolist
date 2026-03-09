import 'package:isar/isar.dart';

import 'package:todo_list_flutter/data/models/task.dart';
import 'package:todo_list_flutter/domain/entities/task_entity.dart';
import 'package:todo_list_flutter/domain/repositories/task_repository.dart';

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl({required this.isar});

  final Isar isar;

  @override
  Future<List<TaskEntity>> getTasks() async {
    try {
      final isarTasks = await isar.tasks.where().findAll();
      isarTasks.sort(_sortTaskModels);

      final tasks = isarTasks.map((task) => task.toEntity()).toList();
      tasks.sort(_sortTasks);
      return tasks;
    } catch (error, stackTrace) {
      throw Exception('Failed to load tasks: $error');
    }
  }

  @override
  Future<List<String>> getProjectNames() async {
    try {
      final tasks = await getTasks();
      final projects = tasks
          .map((task) => task.project)
          .where((project) => project != null && project.trim().isNotEmpty)
          .map((project) => project!.trim())
          .toSet()
          .toList()
        ..sort();

      if (!projects.contains('Inbox')) {
        projects.insert(0, 'Inbox');
      }

      return projects;
    } catch (error, stackTrace) {
      throw Exception('Failed to load projects: $error');
    }
  }

  @override
  Future<List<TaskEntity>> getTasksByDate(DateTime date) async {
    try {
      final allTasks = await getTasks();
      final target = DateTime(date.year, date.month, date.day);
      final nextDay = target.add(const Duration(days: 1));

      final tasks = allTasks.where((task) {
        if (task.dueDate == null) return false;
        return !task.dueDate!.isBefore(target) && task.dueDate!.isBefore(nextDay);
      }).toList();

      tasks.sort(_sortTasks);
      return tasks;
    } catch (error, stackTrace) {
      throw Exception('Failed to load tasks for date: $error');
    }
  }

  @override
  Future<List<TaskEntity>> getUpcomingTasks({int days = 14}) async {
    try {
      final allTasks = await getTasks();
      final today = _startOfDay(DateTime.now());
      final limit = today.add(Duration(days: days));

      final tasks = allTasks.where((task) {
        if (task.dueDate == null) return false;
        return !task.dueDate!.isBefore(today) && task.dueDate!.isBefore(limit);
      }).toList();

      tasks.sort(_sortTasks);
      return tasks;
    } catch (error, stackTrace) {
      throw Exception('Failed to load upcoming tasks: $error');
    }
  }

  @override
  Future<TaskEntity> addTask(TaskEntity task) async {
    try {
      final isarTask = Task.fromEntity(task);
      final id = await isar.writeTxn(() async {
        return isar.tasks.put(isarTask);
      });
      return isarTask.copyWith(id: id).toEntity();
    } catch (error, stackTrace) {
      throw Exception('Failed to add task: $error');
    }
  }

  @override
  Future<TaskEntity> updateTask(TaskEntity task) async {
    if (task.id == null) {
      throw ArgumentError('Cannot update a task without id.');
    }

    try {
      final isarTask = Task.fromEntity(task);
      await isar.writeTxn(() async {
        await isar.tasks.put(isarTask);
      });
      return isarTask.toEntity();
    } catch (error, stackTrace) {
      throw Exception('Failed to update task: $error');
    }
  }

  @override
  Future<void> deleteTask(int id) async {
    try {
      await isar.writeTxn(() async {
        await isar.tasks.delete(id);
      });
    } catch (error, stackTrace) {
      throw Exception('Failed to delete task: $error');
    }
  }

  int _sortTasks(TaskEntity a, TaskEntity b) {
    final aCompleted = a.isCompleted;
    final bCompleted = b.isCompleted;
    if (aCompleted != bCompleted) {
      if (aCompleted) return 1;
      return -1;
    }

    if (a.dueDate != null && b.dueDate != null) {
      final compareDate = a.dueDate!.compareTo(b.dueDate!);
      if (compareDate != 0) return compareDate;
    } else if (a.dueDate != null) {
      return -1;
    } else if (b.dueDate != null) {
      return 1;
    }

    final priorityDiff = b.priority.compareTo(a.priority);
    if (priorityDiff != 0) return priorityDiff;

    return b.createdAt.compareTo(a.createdAt);
  }

  int _sortTaskModels(Task a, Task b) {
    final aCompleted = a.isCompleted;
    final bCompleted = b.isCompleted;
    if (aCompleted != bCompleted) {
      if (aCompleted) return 1;
      return -1;
    }

    if (a.dueDate != null && b.dueDate != null) {
      final compareDate = a.dueDate!.compareTo(b.dueDate!);
      if (compareDate != 0) return compareDate;
    } else if (a.dueDate != null) {
      return -1;
    } else if (b.dueDate != null) {
      return 1;
    }

    final priorityDiff = b.priority.compareTo(a.priority);
    if (priorityDiff != 0) return priorityDiff;

    return b.createdAt.compareTo(a.createdAt);
  }

  DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
