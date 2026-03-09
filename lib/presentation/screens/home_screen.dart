import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:todo_list_flutter/domain/entities/task_entity.dart';
import 'package:todo_list_flutter/presentation/providers/task_notifier.dart';
import 'package:todo_list_flutter/presentation/providers/task_view_providers.dart';
import 'package:todo_list_flutter/presentation/widgets/add_task_bottom_sheet.dart';
import 'package:todo_list_flutter/presentation/widgets/metadata_manager_bottom_sheet.dart';
import 'package:todo_list_flutter/presentation/widgets/task_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _sections = const [
    _TodoSection(label: 'Inbox', mode: TodoViewMode.inbox, icon: Icons.inbox_outlined),
    _TodoSection(label: 'Today', mode: TodoViewMode.today, icon: Icons.today_outlined),
    _TodoSection(label: 'Upcoming', mode: TodoViewMode.upcoming, icon: Icons.event),
    _TodoSection(label: 'Calendar', mode: TodoViewMode.calendar, icon: Icons.calendar_month_outlined),
    _TodoSection(label: 'All', mode: TodoViewMode.all, icon: Icons.view_agenda_outlined),
    _TodoSection(label: 'Done', mode: TodoViewMode.completed, icon: Icons.done_all_outlined),
  ];

  int _selectedSectionIndex = 0;

  @override
  void initState() {
    super.initState();
    ref.read(taskViewModeProvider.notifier).state = _sections[_selectedSectionIndex].mode;
  }

  @override
  Widget build(BuildContext context) {
    final selectedMode = _sections[_selectedSectionIndex].mode;
    final theme = Theme.of(context);
    final tasksState = ref.watch(filteredTasksProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final isBulkMode = ref.watch(bulkSelectionModeProvider);
    final selectedTaskIds = ref.watch(bulkSelectionProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        title: Text(
          'My Tasks',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (isBulkMode && selectedTaskIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: Chip(
                  label: Text('${selectedTaskIds.length} selected'),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          if (isBulkMode) ...[
            if (selectedTaskIds.isNotEmpty) ...[
              IconButton(
                tooltip: 'Mark selected as done',
                icon: const Icon(Icons.done),
                onPressed: () async {
                  await _bulkSetCompleted(true, selectedTaskIds);
                },
              ),
              IconButton(
                tooltip: 'Mark selected as not done',
                icon: const Icon(Icons.remove_done),
                onPressed: () async {
                  await _bulkSetCompleted(false, selectedTaskIds);
                },
              ),
              IconButton(
                tooltip: 'Move selected to project',
                icon: const Icon(Icons.drive_file_move_rtl),
                onPressed: () {
                  _openMoveToProjectSheet(context, selectedTaskIds);
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'set_label') {
                    _openBulkLabelSheet(context, selectedTaskIds);
                  } else if (value == 'delete') {
                    _bulkDelete(selectedTaskIds);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'set_label', child: Text('Set labels')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ] else ...[
              IconButton(
                tooltip: 'Select all visible',
                icon: const Icon(Icons.select_all),
                onPressed: () {
                  tasksState.whenData((tasks) {
                    ref.read(bulkSelectionProvider.notifier).selectAll(tasks);
                  });
                },
              ),
            ],
            IconButton(
              tooltip: 'Exit bulk mode',
              icon: const Icon(Icons.close),
              onPressed: _exitBulkMode,
            ),
          ] else ...[
            IconButton(
              tooltip: 'Clear completed',
              icon: Icon(
                selectedMode == TodoViewMode.all ? Icons.access_time : Icons.cleaning_services_outlined,
              ),
              onPressed: () => ref.read(taskNotifierProvider.notifier).clearCompletedTasks(),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz),
              onSelected: (value) {
                if (value == 'projects') {
                  _openMetadataManager(context, manageProjects: true);
                } else if (value == 'labels') {
                  _openMetadataManager(context, manageProjects: false);
                } else if (value == 'bulk') {
                  ref.read(bulkSelectionModeProvider.notifier).state = true;
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'projects', child: Text('Manage projects')),
                PopupMenuItem(value: 'labels', child: Text('Manage labels')),
                PopupMenuItem(value: 'bulk', child: Text('Select tasks')),
              ],
            ),
            PopupMenuButton<TodoSortMode>(
              icon: const Icon(Icons.sort),
              onSelected: (mode) => ref.read(todoSortModeProvider.notifier).state = mode,
              itemBuilder: (context) => const [
                PopupMenuItem(value: TodoSortMode.byDueDate, child: Text('Sort by due date')),
                PopupMenuItem(value: TodoSortMode.byPriority, child: Text('Sort by priority')),
                PopupMenuItem(value: TodoSortMode.byCreatedDate, child: Text('Sort by created date')),
              ],
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search tasks, labels, projects...',
                filled: true,
              ),
            ),
          ),
          if (selectedMode == TodoViewMode.calendar)
            _CalendarInlineStrip(
              selectedDate: ref.watch(selectedCalendarDateProvider),
              onSelectDate: (date) {
                ref.read(selectedCalendarDateProvider.notifier).state = date;
              },
            )
          else if (selectedMode == TodoViewMode.inbox || selectedMode == TodoViewMode.all)
            _projectSelector(context),
          Expanded(
            child: tasksState.when(
              data: (tasks) {
                if (tasks.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        searchQuery.isNotEmpty
                            ? 'No result found'
                            : 'No tasks yet. Tap “+” to create one.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final id = task.id;

                    return TaskCard(
                      task: task,
                      isSelectionMode: isBulkMode,
                      isSelected: id != null ? selectedTaskIds.contains(id) : false,
                      onSelectionChanged: (selected) {
                        if (id == null) return;
                        ref.read(bulkSelectionProvider.notifier).toggle(id);
                      },
                      onToggle: () => ref
                          .read(taskNotifierProvider.notifier)
                          .toggleTaskCompletion(task),
                      onDelete: () {
                        if (id != null) {
                          ref.read(taskNotifierProvider.notifier).removeTask(id);
                        }
                      },
                      onTap: () {
                        if (isBulkMode) {
                          if (id != null) {
                            ref.read(bulkSelectionProvider.notifier).toggle(id);
                          }
                          return;
                        }
                        _openAddTaskSheet(context, task: task);
                      },
                      onLongPress: () {
                        if (!isBulkMode) {
                          ref.read(bulkSelectionModeProvider.notifier).state = true;
                        }
                        if (id != null) {
                          ref.read(bulkSelectionProvider.notifier).toggle(id);
                        }
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Unable to load tasks.',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddTaskSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('New task'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedSectionIndex,
        onDestinationSelected: (index) {
          final nextMode = _sections[index].mode;
          setState(() => _selectedSectionIndex = index);
          ref.read(taskViewModeProvider.notifier).state = nextMode;
          ref.read(searchQueryProvider.notifier).state = '';
          if (nextMode == TodoViewMode.calendar) {
            ref.read(selectedCalendarDateProvider.notifier).state = DateTime.now();
            ref.read(selectedProjectProvider.notifier).state = null;
            ref.read(todoSortModeProvider.notifier).state = TodoSortMode.byDueDate;
          }
        },
        destinations: [
          for (final section in _sections)
            NavigationDestination(icon: Icon(section.icon), label: section.label),
        ],
      ),
    );
  }

  Widget _projectSelector(BuildContext context) {
    final projects = ref.watch(projectNamesProvider);
    final selectedProject = ref.watch(selectedProjectProvider);
    final theme = Theme.of(context);

    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        children: [
          for (final project in projects)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: selectedProject == null
                    ? project == 'All'
                    : selectedProject == project,
                selectedColor: theme.colorScheme.primaryContainer,
                label: Text(project),
                onSelected: (value) {
                  if (!value) return;
                  ref.read(selectedProjectProvider.notifier).state =
                      project == 'All' ? null : project;
                  ref.read(taskViewModeProvider.notifier).state = TodoViewMode.all;
                  setState(() {
                    _selectedSectionIndex = _sections.indexWhere(
                      (section) => section.mode == TodoViewMode.all,
                    );
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  void _openAddTaskSheet(BuildContext context, {TaskEntity? task}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => AddTaskBottomSheet(editingTask: task),
    );
  }

  void _openMetadataManager(BuildContext context, {required bool manageProjects}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => MetadataManagerBottomSheet(manageProjects: manageProjects),
    );
  }

  Future<void> _bulkSetCompleted(bool isCompleted, Set<int> ids) async {
    if (ids.isEmpty) return;
    await ref.read(taskNotifierProvider.notifier).bulkSetCompletion(ids, isCompleted);
    _exitBulkMode();
  }

  Future<void> _bulkDelete(Set<int> ids) async {
    if (ids.isEmpty) return;
    await ref.read(taskNotifierProvider.notifier).deleteTasks(ids);
    _exitBulkMode();
  }

  void _exitBulkMode() {
    ref.read(bulkSelectionModeProvider.notifier).state = false;
    ref.read(bulkSelectionProvider.notifier).clear();
  }

  void _openMoveToProjectSheet(BuildContext context, Set<int> ids) {
    final projects = ref.read(projectNamesProvider).where((project) => project != 'All').toList();

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return _ProjectPickerSheet(
          projects: projects,
          onPick: (project) async {
            await ref.read(taskNotifierProvider.notifier).moveTasksToProject(ids, project);
            if (context.mounted) {
              Navigator.of(context).pop();
            }
            _exitBulkMode();
          },
          onClear: () async {
            await ref.read(taskNotifierProvider.notifier).moveTasksToProject(ids, 'Inbox');
            if (context.mounted) {
              Navigator.of(context).pop();
            }
            _exitBulkMode();
          },
        );
      },
    );
  }

  void _openBulkLabelSheet(BuildContext context, Set<int> ids) {
    final allLabels = ref.read(labelNamesProvider);
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SizedBox(
          height: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Set labels', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Labels (comma separated)',
                  hintText: 'work, urgent, weekly',
                ),
              ),
              const SizedBox(height: 8),
              if (allLabels.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: allLabels
                      .map(
                        (label) => ActionChip(
                          label: Text(label),
                          onPressed: () {
                            final current = controller.text
                                .split(',')
                                .map((item) => item.trim())
                                .where((item) => item.isNotEmpty)
                                .toList();

                            if (!current.contains(label)) {
                              current.add(label);
                            }
                            controller.text = current.join(', ');
                          },
                        ),
                      )
                      .toList(),
                ),
              const Spacer(),
              FilledButton(
                onPressed: () async {
                  final labels = controller.text
                      .split(',')
                      .map((label) => label.trim())
                      .where((label) => label.isNotEmpty)
                      .toList();
                  await ref.read(taskNotifierProvider.notifier).setLabelsForTasks(ids, labels);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                  _exitBulkMode();
                },
                child: const Text('Apply'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class _ProjectPickerSheet extends StatelessWidget {
  const _ProjectPickerSheet({
    required this.projects,
    required this.onPick,
    required this.onClear,
  });

  final List<String> projects;
  final ValueChanged<String> onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Move to project', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    title: const Text('Inbox'),
                    leading: const Icon(Icons.inbox_outlined),
                    onTap: onClear,
                  ),
                  const Divider(),
                  for (final project in projects)
                    ListTile(
                      title: Text(project),
                      onTap: () => onPick(project),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarInlineStrip extends StatelessWidget {
  const _CalendarInlineStrip({
    required this.selectedDate,
    required this.onSelectDate,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysInMonth = DateUtils.getDaysInMonth(selectedDate.year, selectedDate.month);
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => onSelectDate(DateTime(selectedDate.year, selectedDate.month - 1, 1)),
              ),
              Expanded(
                child: Text(
                  '${_monthName(selectedDate.month)} ${selectedDate.year}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => onSelectDate(DateTime(selectedDate.year, selectedDate.month + 1, 1)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 74,
          child: ListView.separated(
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: daysInMonth,
            itemBuilder: (context, index) {
              final date = DateTime(selectedDate.year, selectedDate.month, index + 1);
              return _DayTile(
                date: date,
                label: weekdays[date.weekday - 1],
                isSelected: DateUtils.isSameDay(selectedDate, date),
                isToday: DateUtils.isSameDay(DateTime.now(), date),
                onSelectDate: onSelectDate,
              );
            },
          ),
        ),
      ],
    );
  }

  static String _monthName(int month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[month - 1];
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({
    required this.date,
    required this.label,
    required this.isSelected,
    required this.isToday,
    required this.onSelectDate,
  });

  final DateTime date;
  final String label;
  final bool isSelected;
  final bool isToday;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => onSelectDate(date),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        width: 54,
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isToday ? theme.colorScheme.secondary : Colors.transparent,
            width: 1.2,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${date.day}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodoSection {
  const _TodoSection({
    required this.label,
    required this.mode,
    required this.icon,
  });

  final String label;
  final TodoViewMode mode;
  final IconData icon;
}
