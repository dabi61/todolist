import 'package:todo_list_flutter/domain/entities/task_entity.dart';

abstract class TaskRepository {
  Future<List<TaskEntity>> getTasks();

  Future<List<String>> getProjectNames();

  Future<List<TaskEntity>> getTasksByDate(DateTime date);

  Future<List<TaskEntity>> getUpcomingTasks({int days});

  Future<TaskEntity> addTask(TaskEntity task);

  Future<TaskEntity> updateTask(TaskEntity task);

  Future<void> deleteTask(int id);
}
