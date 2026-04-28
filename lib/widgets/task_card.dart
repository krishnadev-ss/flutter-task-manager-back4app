import 'package:flutter/material.dart';

import '../models/task_model.dart';
import '../utils/app_date_utils.dart';

/// A dismissible card that represents a single [TaskModel].
///
/// Swiping left shows a delete action. Tapping calls [onTap].
/// The leading checkbox calls [onToggle].
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  final TaskModel task;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isOverdue =
        !task.isCompleted && AppDateUtils.isOverdue(task.dueDate);

    return Dismissible(
      key: ValueKey(task.objectId),
      direction: DismissDirection.endToStart,
      background: _DeleteBackground(colorScheme: colorScheme),
      confirmDismiss: (_) async => false, // deletion is handled by onDelete
      onDismissed: (_) {},
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Completion checkbox
                Checkbox(
                  value: task.isCompleted,
                  onChanged: (_) => onToggle(),
                  shape: const CircleBorder(),
                  activeColor: colorScheme.primary,
                ),
                const SizedBox(width: 4),
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10, right: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          task.title,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: task.isCompleted
                                ? colorScheme.onSurfaceVariant
                                : colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Description
                        if (task.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            task.description,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        // Due date chip
                        if (task.dueDate != null) ...[
                          const SizedBox(height: 8),
                          _DueDateChip(
                            label: AppDateUtils.relative(task.dueDate),
                            isOverdue: isOverdue,
                            isCompleted: task.isCompleted,
                            colorScheme: colorScheme,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Action menu
                PopupMenuButton<_CardAction>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onSelected: (action) {
                    switch (action) {
                      case _CardAction.edit:
                        onTap();
                      case _CardAction.delete:
                        onDelete();
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: _CardAction.edit,
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: _CardAction.delete,
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _CardAction { edit, delete }

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: Icon(
        Icons.delete_outline_rounded,
        color: colorScheme.onErrorContainer,
      ),
    );
  }
}

class _DueDateChip extends StatelessWidget {
  const _DueDateChip({
    required this.label,
    required this.isOverdue,
    required this.isCompleted,
    required this.colorScheme,
  });

  final String label;
  final bool isOverdue;
  final bool isCompleted;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final Color bg = isCompleted
        ? colorScheme.surfaceContainerHighest
        : isOverdue
            ? colorScheme.errorContainer
            : colorScheme.secondaryContainer;
    final Color fg = isCompleted
        ? colorScheme.onSurfaceVariant
        : isOverdue
            ? colorScheme.onErrorContainer
            : colorScheme.onSecondaryContainer;
    final IconData iconData = isOverdue && !isCompleted
        ? Icons.warning_amber_rounded
        : Icons.calendar_today_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
