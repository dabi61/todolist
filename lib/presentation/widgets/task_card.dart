import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:todo_list_flutter/domain/entities/task_entity.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
    this.onTap,
    this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelectionChanged,
  });

  final TaskEntity task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelectionMode;
  final bool isSelected;
  final ValueChanged<bool>? onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final isOverdue = task.dueDate != null &&
        !task.isCompleted &&
        task.dueDate!.isBefore(DateTime(now.year, now.month, now.day));
    final dueDateText = task.dueDate == null
        ? null
        : DateFormat('EEE, MMM d • HH:mm').format(task.dueDate!);
    final reminderText = task.reminderAt == null
        ? null
        : DateFormat('EEE, MMM d • HH:mm').format(task.reminderAt!);

    return Card(
      elevation: 1.2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isSelectionMode)
                Checkbox(
                  value: isSelected,
                  onChanged: (value) {
                    if (value != null) {
                      onSelectionChanged?.call(value);
                    }
                  },
                )
              else
                Checkbox(
                  value: task.isCompleted,
                  onChanged: (_) => onToggle(),
                ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      task.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        decoration:
                            task.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                        color: task.isCompleted ? theme.colorScheme.onSurfaceVariant : null,
                      ),
                    ),
                    if (task.description != null && task.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (isOverdue)
                          _InfoPill(
                            label: 'Overdue',
                            icon: Icons.warning_amber_outlined,
                            color: theme.colorScheme.errorContainer,
                            foregroundColor: theme.colorScheme.onErrorContainer,
                          ),
                        if (task.project != null && task.project!.isNotEmpty)
                          _InfoPill(
                            label: task.project!,
                            color: theme.colorScheme.tertiaryContainer,
                            foregroundColor: theme.colorScheme.onTertiaryContainer,
                            icon: Icons.folder_outlined,
                          ),
                        if (dueDateText != null)
                          _InfoPill(
                            label: dueDateText,
                            icon: Icons.schedule,
                            color: theme.colorScheme.primaryContainer,
                            foregroundColor: theme.colorScheme.onPrimaryContainer,
                          ),
                        if (task.labels.isNotEmpty)
                          _InfoPill(
                            label: task.labels.join(', '),
                            icon: Icons.sell,
                            color: theme.colorScheme.secondaryContainer,
                            foregroundColor: theme.colorScheme.onSecondaryContainer,
                          ),
                        if (task.reminderAt != null)
                          _InfoPill(
                            label: 'Remind ${reminderText ?? ''}',
                            icon: Icons.alarm_add_rounded,
                            color: theme.colorScheme.surfaceTint,
                            foregroundColor: theme.colorScheme.onPrimary,
                          ),
                        if (task.isRecurring)
                          _InfoPill(
                            label: task.recurrenceRule ?? 'Recurring',
                            icon: Icons.refresh,
                            color: theme.colorScheme.errorContainer,
                            foregroundColor: theme.colorScheme.onErrorContainer,
                          ),
                        if (task.priority > 0) _PriorityBadge(task: task, theme: theme),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isSelectionMode)
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete task',
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({
    required this.task,
    required this.theme,
  });

  final TaskEntity task;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final label = task.priority >= 3
        ? 'P1'
        : task.priority == 2
            ? 'P2'
            : 'P3';
    final text = task.priority == 3
        ? theme.colorScheme.onErrorContainer
        : theme.colorScheme.onPrimaryContainer;

    return _InfoPill(
      label: label,
      icon: Icons.flag,
      color: task.priority == 3
          ? theme.colorScheme.errorContainer
          : theme.colorScheme.primaryContainer,
      foregroundColor: text,
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.label,
    required this.color,
    required this.foregroundColor,
    this.icon,
  });

  final String label;
  final Color color;
  final Color foregroundColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Chip(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: BorderSide(color: color.withAlpha(0)),
      backgroundColor: color,
      avatar: icon == null ? null : Icon(icon, size: 14, color: foregroundColor),
      labelPadding: icon == null ? const EdgeInsets.symmetric(horizontal: 4) : null,
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: foregroundColor,
        ),
      ),
    );
  }
}
