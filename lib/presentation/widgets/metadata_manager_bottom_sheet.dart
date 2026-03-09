import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:todo_list_flutter/core/providers/app_providers.dart';
import 'package:todo_list_flutter/domain/entities/label_entity.dart';
import 'package:todo_list_flutter/domain/entities/project_entity.dart';
import 'package:todo_list_flutter/presentation/providers/task_view_providers.dart';

class MetadataManagerBottomSheet extends ConsumerWidget {
  const MetadataManagerBottomSheet({
    super.key,
    required this.manageProjects,
  });

  final bool manageProjects;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (manageProjects) {
      final projects = ref.watch(projectListProvider);
      return projects.when(
        data: (items) => _ProjectManagementSection(
          projects: items,
          onRefresh: () => ref.invalidate(projectListProvider),
        ),
        loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => const Padding(
          padding: EdgeInsets.all(24),
          child: Text('Failed to load projects'),
        ),
      );
    }

    final labels = ref.watch(labelListProvider);
    return labels.when(
      data: (items) => _LabelManagementSection(
        labels: items,
        onRefresh: () => ref.invalidate(labelListProvider),
      ),
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const Padding(
        padding: EdgeInsets.all(24),
        child: Text('Failed to load labels'),
      ),
    );
  }
}

class _ProjectManagementSection extends ConsumerWidget {
  const _ProjectManagementSection({
    required this.projects,
    required this.onRefresh,
  });

  final List<ProjectEntity> projects;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 420,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Manage projects', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () => _upsertCollection(context, ref),
              child: const Text('Add project'),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: projects.isEmpty
                  ? const Center(child: Text('No projects yet'))
                  : ListView.separated(
                      itemCount: projects.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, index) {
                        final project = projects[index];
                        final isDefault =
                            project.name.toLowerCase() == 'inbox';

                        return ListTile(
                          title: Text(project.name),
                          subtitle: project.isArchived ? const Text('Archived') : null,
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'rename') {
                                await _renameCollection(context, ref, project);
                              } else if (value == 'delete') {
                                await _deleteCollection(context, ref, project);
                              }
                            },
                            itemBuilder: (context) {
                              return [
                                const PopupMenuItem(value: 'rename', child: Text('Rename')),
                                if (!isDefault)
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                              ];
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _upsertCollection(BuildContext context, WidgetRef ref) async {
    final name = await _promptName(context, title: 'New project');
    if (name == null || name.isEmpty) return;

    final repository = ref.read(projectRepositoryProvider);
    await repository.addProject(ProjectEntity(name: name, createdAt: DateTime.now()));
    onRefresh();
  }

  Future<void> _renameCollection(BuildContext context, WidgetRef ref, ProjectEntity project) async {
    final name = await _promptName(context, title: 'Rename project', initialValue: project.name);
    if (name == null || name.isEmpty || project.id == null) return;

    final repository = ref.read(projectRepositoryProvider);
    await repository.updateProject(project.copyWith(name: name));
    onRefresh();
  }

  Future<void> _deleteCollection(BuildContext context, WidgetRef ref, ProjectEntity project) async {
    if (project.id == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete project'),
        content: Text('Delete "${project.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );

    if (shouldDelete != true) return;

    final repository = ref.read(projectRepositoryProvider);
    await repository.deleteProject(project.id!);
    onRefresh();
  }

  Future<String?> _promptName(
    BuildContext context, {
    required String title,
    String? initialValue,
  }) async {
    final controller = TextEditingController(text: initialValue ?? '');
    return showDialog<String>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

class _LabelManagementSection extends ConsumerWidget {
  const _LabelManagementSection({
    required this.labels,
    required this.onRefresh,
  });

  final List<LabelEntity> labels;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 420,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Manage labels', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () => _upsertLabel(context, ref),
              child: const Text('Add label'),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: labels.isEmpty
                  ? const Center(child: Text('No labels yet'))
                  : ListView.separated(
                      itemCount: labels.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, index) {
                        final label = labels[index];
                        return ListTile(
                          title: Text(label.name),
                          subtitle: label.isArchived ? const Text('Archived') : null,
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'rename') {
                                await _renameLabel(context, ref, label);
                              } else if (value == 'delete') {
                                await _deleteLabel(context, ref, label);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(value: 'rename', child: Text('Rename')),
                              PopupMenuItem(value: 'delete', child: Text('Delete')),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _upsertLabel(BuildContext context, WidgetRef ref) async {
    final name = await _promptName(context, title: 'New label');
    if (name == null || name.isEmpty) return;

    final repository = ref.read(labelRepositoryProvider);
    await repository.addLabel(LabelEntity(name: name, createdAt: DateTime.now()));
    onRefresh();
  }

  Future<void> _renameLabel(BuildContext context, WidgetRef ref, LabelEntity label) async {
    final name = await _promptName(context, title: 'Rename label', initialValue: label.name);
    if (name == null || name.isEmpty || label.id == null) return;

    final repository = ref.read(labelRepositoryProvider);
    await repository.updateLabel(label.copyWith(name: name));
    onRefresh();
  }

  Future<void> _deleteLabel(BuildContext context, WidgetRef ref, LabelEntity label) async {
    if (label.id == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete label'),
        content: Text('Delete "${label.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );

    if (shouldDelete != true) return;

    final repository = ref.read(labelRepositoryProvider);
    await repository.deleteLabel(label.id!);
    onRefresh();
  }

  Future<String?> _promptName(
    BuildContext context, {
    required String title,
    String? initialValue,
  }) async {
    final controller = TextEditingController(text: initialValue ?? '');
    return showDialog<String>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
