import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import 'package:todo_list_flutter/data/repositories/label_repository_impl.dart';
import 'package:todo_list_flutter/data/repositories/project_repository_impl.dart';
import 'package:todo_list_flutter/data/repositories/task_repository_impl.dart';
import 'package:todo_list_flutter/domain/repositories/label_repository.dart';
import 'package:todo_list_flutter/domain/repositories/project_repository.dart';
import 'package:todo_list_flutter/domain/repositories/task_repository.dart';

final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError('Isar has not been initialized in ProviderScope');
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return TaskRepositoryImpl(isar: isar);
});

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return ProjectRepositoryImpl(isar: isar);
});

final labelRepositoryProvider = Provider<LabelRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return LabelRepositoryImpl(isar: isar);
});
