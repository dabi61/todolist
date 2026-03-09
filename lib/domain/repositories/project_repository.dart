import 'package:todo_list_flutter/domain/entities/project_entity.dart';

abstract class ProjectRepository {
  Future<List<ProjectEntity>> getProjects();

  Future<ProjectEntity?> getProjectByName(String name);

  Future<ProjectEntity?> getProjectById(int id);

  Future<ProjectEntity> upsertProjectByName(String name, {int? color});

  Future<ProjectEntity> addProject(ProjectEntity project);

  Future<ProjectEntity> updateProject(ProjectEntity project);

  Future<void> deleteProject(int id);
}
