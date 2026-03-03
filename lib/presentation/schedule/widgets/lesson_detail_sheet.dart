import 'package:flutter/material.dart';
import 'package:bsharp/domain/schedule_utils.dart';
import 'package:bsharp/l10n/strings.g.dart';

class LessonDetailSheet extends StatelessWidget {
  const LessonDetailSheet({super.key, required this.entry});

  final ScheduleEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = subjectColor(entry.event.eventTypesId);
    final topPadding = MediaQuery.of(context).padding.top;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight - topPadding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 56,
            child: Row(
              children: [
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text(
                    entry.subjectName ?? t.schedule.lessonFallback,
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${entry.event.number}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.subjectName ?? t.schedule.lessonFallback,
                            style: theme.textTheme.titleLarge?.copyWith(
                              decoration: entry.isCancelled
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          Text(
                            entry.timeRange,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (entry.changeType != null) ...[
                  const SizedBox(height: 12),
                  _StatusBanner(changeType: entry.changeType!),
                ],
                const SizedBox(height: 24),
                if (entry.originalSubjectName != null &&
                    entry.originalSubjectName != entry.subjectName)
                  _DetailRow(
                    icon: Icons.swap_horiz,
                    label: t.schedule.originalSubject,
                    value: entry.originalSubjectName!,
                  ),
                if (entry.originalTeacherName != null &&
                    entry.originalTeacherName != entry.teacherName)
                  _DetailRow(
                    icon: Icons.person_off_outlined,
                    label: t.schedule.originalTeacher,
                    value: entry.originalTeacherName!,
                  ),
                if (entry.teacherName != null)
                  _DetailRow(
                    icon: Icons.person_outline,
                    label: t.schedule.teacher,
                    value: entry.teacherName!,
                  ),
                if (entry.roomName != null)
                  _DetailRow(
                    icon: Icons.room_outlined,
                    label: t.schedule.room,
                    value: entry.roomName!,
                  ),
                _DetailRow(
                  icon: Icons.calendar_today_outlined,
                  label: t.schedule.date,
                  value:
                      '${dayLabelFull(entry.event.date.weekday)}, ${formatDateFull(entry.event.date)}',
                ),
                if (entry.topic != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    t.schedule.lessonTopic,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.topic!,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
                if (entry.isLocked) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        t.schedule.lessonConfirmed,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(value, style: theme.textTheme.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.changeType});

  final ScheduleChangeType changeType;

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (changeType) {
      ScheduleChangeType.cancelled => (
          Icons.cancel_outlined,
          Theme.of(context).colorScheme.error,
          t.schedule.lessonCancelled,
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
          t.schedule.lessonAdded,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
