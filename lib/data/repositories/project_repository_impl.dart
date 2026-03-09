import 'package:isar/isar.dart';

import 'package:todo_list_flutter/data/models/project.dart';
import 'package:todo_list_flutter/domain/entities/project_entity.dart';
import 'package:todo_list_flutter/domain/repositories/project_repository.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  ProjectRepositoryImpl({required this.isar});

  final Isar isar;

  static const String _defaultProjectName = 'Inbox';

  @override
  Future<List<ProjectEntity>> getProjects() async {
    try {
      final projects = await isar.projects.where().findAll();
      final ensuredProjects = [...projects];
      final inbox = ensuredProjects
          .where((project) => project.name.toLowerCase() == _defaultProjectName.toLowerCase())
          .toList();

      if (inbox.isEmpty) {
        final created = await addProject(
          ProjectEntity(
            name: _defaultProjectName,
            color: 0xFF6750A4,
            createdAt: DateTime.now(),
          ),
        );
        ensuredProjects.insert(0, Project.fromEntity(created));
      }

      final sorted = [...ensuredProjects]
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return sorted.map((project) => project.toEntity()).toList();
    } catch (error, stackTrace) {
      throw Exception('Failed to load projects: $error');
    }
  }

  @override
  Future<ProjectEntity?> getProjectByName(String name) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) return null;

    try {
      final projects = await isar.projects.where().findAll();
      final match = projects.where((project) {
        return project.name.toLowerCase() == normalizedName.toLowerCase();
      }).toList();

      if (match.isEmpty) return null;
      return match.first.toEntity();
    } catch (error, stackTrace) {
      throw Exception('Failed to get project by name: $error');
    }
  }

  @override
  Future<ProjectEntity?> getProjectById(int id) async {
    try {
      final project = await isar.projects.get(id);
      return project?.toEntity();
    } catch (error, stackTrace) {
      throw Exception('Failed to get project by id: $error');
    }
  }

  @override
  Future<ProjectEntity> upsertProjectByName(String name, {int? color}) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError('Project name cannot be empty.');
    }

    try {
      final existing = await getProjectByName(normalizedName);
      if (existing != null) {
        if (color == null || color == existing.color) {
          return existing;
        }

        final updated = existing.copyWith(color: color);
        return updateProject(updated);
      }

      return addProject(
        ProjectEntity(name: normalizedName, color: color ?? 0xFF6750A4, createdAt: DateTime.now()),
      );
    } catch (error, stackTrace) {
      throw Exception('Failed to upsert project: $error');
    }
  }

  @override
  Future<ProjectEntity> addProject(ProjectEntity project) async {
    final normalizedName = project.name.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError('Project name cannot be empty.');
    }

    try {
      final isarProject = Project.fromEntity(project.copyWith(name: normalizedName));
      final id = await isar.writeTxn(() async {
        return isar.projects.put(isarProject);
      });
      return isarProject.copyWith(id: id).toEntity();
    } catch (error, stackTrace) {
      throw Exception('Failed to add project: $error');
    }
  }

  @override
  Future<ProjectEntity> updateProject(ProjectEntity project) async {
    if (project.id == null) {
      throw ArgumentError('Cannot update a project without id.');
    }

    final normalizedName = project.name.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError('Project name cannot be empty.');
    }

    try {
      final updatedProject = project.copyWith(name: normalizedName);
      final isarProject = Project.fromEntity(updatedProject);
      await isar.writeTxn(() async {
        await isar.projects.put(isarProject);
      });
      return isarProject.toEntity();
    } catch (error, stackTrace) {
      throw Exception('Failed to update project: $error');
    }
  }

  @override
  Future<void> deleteProject(int id) async {
    try {
      final project = await isar.projects.get(id);
      if (project == null) return;

      if (project.name.toLowerCase() == _defaultProjectName.toLowerCase()) {
        throw StateError('Cannot delete default project "$_defaultProjectName".');
      }

      await isar.writeTxn(() async {
        await isar.projects.delete(id);
      });
    } catch (error, stackTrace) {
      throw Exception('Failed to delete project: $error');
    }
  }
}
