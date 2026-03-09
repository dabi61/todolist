import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:todo_list_flutter/domain/entities/task_entity.dart';
import 'package:todo_list_flutter/presentation/providers/task_notifier.dart';
import 'package:todo_list_flutter/presentation/providers/task_view_providers.dart';

class AddTaskBottomSheet extends ConsumerStatefulWidget {
  const AddTaskBottomSheet({super.key, this.editingTask});

  final TaskEntity? editingTask;

  @override
  ConsumerState<AddTaskBottomSheet> createState() => _AddTaskBottomSheetState();
}

class _AddTaskBottomSheetState extends ConsumerState<AddTaskBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _labelsController;
  late final TextEditingController _projectController;

  String _selectedProject = 'Inbox';
  int _priority = 0;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  bool _isRecurring = false;
  String _recurrenceFrequency = 'Daily';
  int _recurrenceEvery = 1;
  bool _setReminder = false;
  DateTime? _reminderAt;

  final _frequencyOptions = const [
    'Daily',
    'Weekday',
    'Weekly',
    'Monthly',
    'Yearly',
  ];

  @override
  void initState() {
    super.initState();
    final task = widget.editingTask;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController = TextEditingController(text: task?.description ?? '');
    _labelsController = TextEditingController(text: (task?.labels ?? const <String>[]).join(', '));
    _projectController = TextEditingController(text: task?.project ?? 'Inbox');

    _selectedProject = (task?.project?.trim().isEmpty ?? true) ? 'Inbox' : task!.project!.trim();
    _priority = task?.priority ?? 0;
    _dueDate = task?.dueDate;
    _dueTime = task?.dueDate == null
        ? null
        : TimeOfDay(hour: task!.dueDate!.hour, minute: task.dueDate!.minute);
    _setReminder = task?.reminderAt != null;
    _reminderAt = task?.reminderAt;
    _isRecurring = task?.isRecurring ?? false;
    _applyRecurrenceRule(task?.recurrenceRule);

    _projectController.addListener(() {
      _selectedProject = _projectController.text.trim().isEmpty
          ? 'Inbox'
          : _projectController.text.trim();
    });
  }

  void _applyRecurrenceRule(String? rule) {
    if (rule == null || rule.trim().isEmpty) {
      _recurrenceFrequency = 'Daily';
      _recurrenceEvery = 1;
      return;
    }

    final lower = rule.toLowerCase();

    if (lower.contains('weekday')) {
      _recurrenceFrequency = 'Weekday';
      _recurrenceEvery = 1;
      return;
    }

    if (lower.contains('weekly')) {
      _recurrenceFrequency = 'Weekly';
    } else if (lower.contains('monthly')) {
      _recurrenceFrequency = 'Monthly';
    } else if (lower.contains('yearly') || lower.contains('annual')) {
      _recurrenceFrequency = 'Yearly';
    } else {
      _recurrenceFrequency = 'Daily';
    }

    final numbers = RegExp(r'(\d+)').firstMatch(rule);
    if (numbers != null) {
      _recurrenceEvery = int.tryParse(numbers.group(1)!) ?? 1;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _labelsController.dispose();
    _projectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.editingTask != null;
    final theme = Theme.of(context);
    final projects = ref.watch(projectNamesProvider).where((project) => project != 'All').toList();
    final labels = ref.watch(labelNamesProvider);
    final dueDateLabel =
        _dueDate == null ? 'Set date' : DateFormat('EEE, MMM d').format(_dueDate!);
    final dueTimeLabel = _dueTime == null ? 'Set time' : _dueTime!.format(context);
    final reminderLabel = _reminderAt == null
        ? 'Set reminder'
        : DateFormat('EEE, MMM d HH:mm').format(_reminderAt!);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditMode ? 'Edit task' : 'Add task',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                minLines: 2,
                maxLines: 4,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _projectController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Project',
                  hintText: 'Enter a project name (Inbox if empty)',
                ),
              ),
              if (projects.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: projects
                      .map(
                        (project) => ActionChip(
                          label: Text(project),
                          onPressed: () {
                            _projectController.text = project;
                            setState(() {
                              _selectedProject = project;
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _labelsController,
                decoration: const InputDecoration(
                  labelText: 'Labels (comma separated)',
                  helperText: 'Ví dụ: work, urgent, weekly',
                ),
              ),
              if (labels.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Quick labels', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    for (final label in labels.where((label) => !_labelsFromText().contains(label)))
                      ActionChip(
                        label: Text(label),
                        onPressed: () {
                          _appendLabel(label);
                        },
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Text('Priority', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('None'), icon: Icon(Icons.remove)),
                  ButtonSegment(value: 1, label: Text('P3'), icon: Icon(Icons.flag)),
                  ButtonSegment(value: 2, label: Text('P2'), icon: Icon(Icons.flag)),
                  ButtonSegment(value: 3, label: Text('P1'), icon: Icon(Icons.flag)),
                ],
                selected: {_priority},
                showSelectedIcon: false,
                onSelectionChanged: (values) {
                  setState(() => _priority = values.first);
                },
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonal(
                    onPressed: () => _pickDueDate(context),
                    child: Text('Due date: $dueDateLabel'),
                  ),
                  if (_dueDate != null)
                    FilledButton.tonal(
                      onPressed: () => _pickDueTime(context),
                      child: Text('Due time: $dueTimeLabel'),
                    ),
                  FilledButton.tonal(
                    onPressed: () => _pickReminder(context),
                    child: Text(_setReminder ? 'Reminder: $reminderLabel' : reminderLabel),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: _isRecurring,
                    onChanged: (value) {
                      setState(() => _isRecurring = value ?? false);
                    },
                  ),
                  const Text('Recurring task'),
                ],
              ),
              if (_isRecurring)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SegmentedButton<String>(
                      segments: _frequencyOptions
                          .map((value) => ButtonSegment(value: value, label: Text(value)))
                          .toList(),
                      selected: {_recurrenceFrequency},
                      showSelectedIcon: false,
                      onSelectionChanged: (values) {
                        setState(() {
                          _recurrenceFrequency = values.first;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text('Every', style: theme.textTheme.bodyMedium),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: _recurrenceEvery > 1
                              ? () {
                                  setState(() => _recurrenceEvery--);
                                }
                              : null,
                        ),
                        Text('$_recurrenceEvery', style: theme.textTheme.titleMedium),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () {
                            setState(() => _recurrenceEvery++);
                          },
                        ),
                        const SizedBox(width: 8),
                        Text(_recurrenceFrequency.toLowerCase()),
                      ],
                    ),
                    if (_recurrenceFrequency == 'Weekday')
                      Text(
                        'Applies Monday to Friday',
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: _setReminder,
                    onChanged: (value) {
                      if (value == true) {
                        setState(() {
                          _setReminder = true;
                        });
                        if (_reminderAt == null) {
                          _pickReminder(context);
                        }
                      } else {
                        setState(() {
                          _setReminder = false;
                          _reminderAt = null;
                        });
                      }
                    },
                  ),
                  const Text('Set reminder'),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _handleSave,
                child: Text(isEditMode ? 'Update' : 'Save'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _labelsFromText() {
    return _labelsController.text
        .split(',')
        .map((label) => label.trim())
        .where((label) => label.isNotEmpty)
        .toList();
  }

  void _appendLabel(String label) {
    final existing = _labelsFromText();
    if (existing.contains(label)) return;

    final updated = [...existing, label];
    _labelsController.text = updated.join(', ');
    setState(() {});
  }

  Future<void> _pickDueDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: _dueDate ?? DateTime.now(),
    );
    if (picked == null) return;

    setState(() {
      _dueDate = picked;
    });
  }

  Future<void> _pickDueTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked == null) return;

    setState(() => _dueTime = picked);
  }

  Future<void> _pickReminder(BuildContext context) async {
    final initialDate = _dueDate ?? DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: initialDate,
    );

    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (pickedTime == null) return;

    setState(() {
      _setReminder = true;
      _reminderAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState?.validate() != true) return;

    DateTime? dueDate;
    if (_dueDate != null) {
      dueDate = DateTime(
        _dueDate!.year,
        _dueDate!.month,
        _dueDate!.day,
        _dueTime?.hour ?? 0,
        _dueTime?.minute ?? 0,
      );
      if (_dueTime == null && dueDate.hour == 0 && dueDate.minute == 0) {
        dueDate = DateTime(_dueDate!.year, _dueDate!.month, _dueDate!.day);
      }
    }

    final recurrenceRule = _isRecurring ? _buildRecurrenceRule() : null;

    await ref.read(taskNotifierProvider.notifier).saveTask(
          editingTask: widget.editingTask,
          title: _titleController.text,
          description: _descriptionController.text,
          project: _selectedProject == 'Inbox' ? null : _selectedProject,
          labels: _labelsFromText(),
          priority: _priority,
          dueDate: dueDate,
          reminderAt: _setReminder ? _reminderAt : null,
          isRecurring: _isRecurring,
          recurrenceRule: recurrenceRule,
        );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  String _buildRecurrenceRule() {
    if (_recurrenceFrequency == 'Weekday') {
      return 'Weekday';
    }

    final interval = _recurrenceEvery.clamp(1, 365);

    switch (_recurrenceFrequency) {
      case 'Weekly':
        return 'Every $interval week';
      case 'Monthly':
        return 'Every $interval month';
      case 'Yearly':
        return 'Every $interval year';
      default:
        return 'Every $interval day';
    }
  }
}
