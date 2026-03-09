import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:todo_list_flutter/core/providers/app_providers.dart';
import 'package:todo_list_flutter/domain/entities/label_entity.dart';
import 'package:todo_list_flutter/domain/entities/project_entity.dart';
import 'package:todo_list_flutter/domain/entities/task_entity.dart';
import 'package:todo_list_flutter/presentation/providers/task_notifier.dart';

enum TodoViewMode {
  inbox,
  today,
  upcoming,
  all,
  completed,
  calendar,
}

enum TodoSortMode {
  byDueDate,
  byPriority,
  byCreatedDate,
}

final taskViewModeProvider = StateProvider<TodoViewMode>((_) => TodoViewMode.inbox);
final searchQueryProvider = StateProvider<String>((_) => '');
final selectedProjectProvider = StateProvider<String?>((_) => null);
final selectedCalendarDateProvider = StateProvider<DateTime>((_) => DateTime.now());
final todoSortModeProvider = StateProvider<TodoSortMode>((_) => TodoSortMode.byDueDate);

final bulkSelectionModeProvider = StateProvider<bool>((_) => false);

class BulkSelectionNotifier extends StateNotifier<Set<int>> {
  BulkSelectionNotifier() : super(<int>{});

  void clear() => state = <int>{};

  void toggle(int id) {
    final newState = {...state};
    if (newState.contains(id)) {
      newState.remove(id);
    } else {
      newState.add(id);
    }
    state = newState;
  }

  void selectAll(List<TaskEntity> tasks) {
    state = tasks
        .where((task) => task.id != null)
        .map((task) => task.id!)
        .toSet();
  }
}

final bulkSelectionProvider = StateNotifierProvider<BulkSelectionNotifier, Set<int>>(
  (ref) => BulkSelectionNotifier(),
);

final projectListProvider = FutureProvider<List<ProjectEntity>>((ref) async {
  final repository = ref.read(projectRepositoryProvider);
  return repository.getProjects();
});

final labelListProvider = FutureProvider<List<LabelEntity>>((ref) async {
  final repository = ref.read(labelRepositoryProvider);
  return repository.getLabels();
});

final projectNamesProvider = Provider<List<String>>((ref) {
  final projects = ref.watch(projectListProvider).when(
    data: (items) => items,
    loading: () => const <ProjectEntity>[],
    error: (_, __) => const <ProjectEntity>[],
  );

  final names = projects
      .where((project) => !project.isArchived)
      .map((project) => project.name.trim())
      .where((name) => name.isNotEmpty)
      .toSet()
      .toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  if (!names.contains('Inbox')) {
    names.insert(0, 'Inbox');
  }

  if (!names.contains('All')) {
    names.insert(0, 'All');
  }

  return names;
});

final labelNamesProvider = Provider<List<String>>((ref) {
  final labels = ref.watch(labelListProvider).when(
    data: (items) => items,
    loading: () => const <LabelEntity>[],
    error: (_, __) => const <LabelEntity>[],
  );

  final names = labels
      .where((label) => !label.isArchived)
      .map((label) => label.name.trim())
      .where((name) => name.isNotEmpty)
      .toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  return names;
});

final filteredTasksProvider = Provider<AsyncValue<List<TaskEntity>>>((ref) {
  final tasksState = ref.watch(taskNotifierProvider);
  final viewMode = ref.watch(taskViewModeProvider);
  final searchQuery = ref.watch(searchQueryProvider);
  final selectedProject = ref.watch(selectedProjectProvider);
  final selectedDate = ref.watch(selectedCalendarDateProvider);
  final sortMode = ref.watch(todoSortModeProvider);

  return tasksState.when(
    data: (tasks) {
      final normalized = searchQuery.trim().toLowerCase();
      final filtered = tasks.where((task) {
        final matchesSearch = normalized.isEmpty ||
            task.title.toLowerCase().contains(normalized) ||
            (task.description ?? '').toLowerCase().contains(normalized) ||
            (task.project ?? '').toLowerCase().contains(normalized) ||
            task.labels.any((label) => label.toLowerCase().contains(normalized));

        final normalizedProject = (task.project ?? 'Inbox').trim();
        final matchesProject = selectedProject == null || selectedProject == 'All'
            ? true
            : normalizedProject == selectedProject;

        switch (viewMode) {
          case TodoViewMode.completed:
            if (!task.isCompleted) return false;
            return matchesSearch && matchesProject;
          case TodoViewMode.all:
            return matchesSearch && matchesProject;
          case TodoViewMode.inbox:
            return !task.isCompleted &&
                ((task.project == null || task.project!.trim().isEmpty || task.project == 'Inbox') &&
                    matchesSearch &&
                    matchesProject);
          case TodoViewMode.today:
            if (task.isCompleted || task.dueDate == null) return false;
            return _isSameDay(task.dueDate!, DateTime.now()) &&
                matchesSearch &&
                matchesProject;
          case TodoViewMode.upcoming:
            if (task.isCompleted || task.dueDate == null) return false;
            final today = _startOfDay(DateTime.now());
            final day14 = today.add(const Duration(days: 14));
            final target = _startOfDay(task.dueDate!);
            return !target.isBefore(today) &&
                target.isBefore(day14) &&
                matchesSearch &&
                matchesProject;
          case TodoViewMode.calendar:
            if (task.isCompleted || task.dueDate == null) return false;
            return _isSameDay(task.dueDate!, selectedDate) &&
                matchesSearch;
        }
      }).toList();

      return AsyncData(_sortTasks(filtered, sortMode));
    },
    error: (error, stack) => AsyncValue.error(error, stack),
    loading: () => const AsyncValue.loading(),
  );
});

List<TaskEntity> _sortTasks(List<TaskEntity> tasks, TodoSortMode sortMode) {
  final sorted = List<TaskEntity>.from(tasks);
  sorted.sort((a, b) {
    if (a.isCompleted != b.isCompleted) {
      return a.isCompleted ? 1 : -1;
    }

    switch (sortMode) {
      case TodoSortMode.byPriority:
        if (a.priority != b.priority) {
          return b.priority.compareTo(a.priority);
        }
        break;
      case TodoSortMode.byCreatedDate:
        return b.createdAt.compareTo(a.createdAt);
      case TodoSortMode.byDueDate:
        if (a.dueDate != null && b.dueDate != null) {
          final dueCompare = a.dueDate!.compareTo(b.dueDate!);
          if (dueCompare != 0) return dueCompare;
        } else if (a.dueDate != null) {
          return -1;
        } else if (b.dueDate != null) {
          return 1;
        }
        break;
    }

    return b.priority.compareTo(a.priority);
  });
  return sorted;
}

DateTime _startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

bool _isSameDay(DateTime a, DateTime b) {
  final aDate = _startOfDay(a);
  final bDate = _startOfDay(b);
  return aDate == bDate;
}
