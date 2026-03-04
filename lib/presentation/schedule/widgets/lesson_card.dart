import 'package:bsharp/domain/schedule_utils.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:flutter/material.dart';

class LessonCard extends StatelessWidget {
  const LessonCard({required this.entry, super.key, this.onTap});

  final ScheduleEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCancelled = entry.isCancelled;
    final color = entry.subjectName != null
        ? subjectColor(entry.event.eventTypesId)
        : theme.colorScheme.outline;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 4,
                color: isCancelled ? theme.colorScheme.error : color,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 48,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${entry.event.number}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                            Text(
                              _formatTimeShort(entry.event.startTime),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    entry.subjectName ??
                                        t.schedule.lessonFallback,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      decoration: isCancelled
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                                if (entry.changeType != null)
                                  _ChangeIndicator(
                                    changeType: entry.changeType!,
                                  ),
                              ],
                            ),
                            if (entry.teacherName != null ||
                                entry.roomName != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  [
                                    if (entry.teacherName != null)
                                      entry.teacherName!,
                                    if (entry.roomName != null)
                                      t.schedule.roomPrefix(
                                        name: entry.roomName!,
                                      ),
                                  ].join(' • '),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            if (entry.topic != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  entry.topic!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        entry.timeRange,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatTimeShort(String time) {
    final parts = time.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return time;
  }
}

class _ChangeIndicator extends StatelessWidget {
  const _ChangeIndicator({required this.changeType});

  final ScheduleChangeType changeType;

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (changeType) {
      ScheduleChangeType.cancelled => (
        Icons.cancel_outlined,
        Theme.of(context).colorScheme.error,
        t.schedule.cancelled,
      ),
      ScheduleChangeType.substitution => (
        Icons.swap_horiz,
        Colors.orange,
        t.schedule.substitution,
      ),
      ScheduleChangeType.roomChanged => (
        Icons.room_outlined,
        Colors.blue,
        t.schedule.roomChanged,
      ),
      ScheduleChangeType.added => (
        Icons.add_circle_outline,
        Colors.green,
        t.schedule.added,
      ),
    };

    return Tooltip(
      message: label,
      child: Icon(icon, size: 18, color: color),
    );
  }
}
