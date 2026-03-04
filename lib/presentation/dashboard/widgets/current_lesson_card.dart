import 'package:bsharp/domain/schedule_utils.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/dashboard/providers/dashboard_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CurrentLessonCard extends ConsumerWidget {
  const CurrentLessonCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(currentLessonProvider);
    final lessons = ref.watch(todayLessonsProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasLesson = data.current != null || data.next != null;
    final entry = data.current ?? data.next;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: hasLesson ? 2 : 0,
      color: hasLesson ? cs.primaryContainer : cs.surfaceContainerHighest,
      child: InkWell(
        onTap: () => StatefulNavigationShell.of(context).goBranch(1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: hasLesson
              ? _ActiveLesson(
                  entry: entry!,
                  isCurrent: data.current != null,
                  lessonsToday: lessons.length,
                )
              : _InactiveLesson(allEnded: data.allEnded),
        ),
      ),
    );
  }
}

class _ActiveLesson extends StatelessWidget {
  const _ActiveLesson({
    required this.entry,
    required this.isCurrent,
    required this.lessonsToday,
  });

  final ScheduleEntry entry;
  final bool isCurrent;
  final int lessonsToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${entry.event.number}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: cs.onPrimary,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              if (isCurrent)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: cs.onPrimary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    t.dashboard.lessonNow,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onPrimary,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isCurrent ? t.dashboard.currentLesson : t.dashboard.nextLesson,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onPrimaryContainer.withValues(alpha: 0.7),
                ),
              ),
              Text(
                entry.subjectName ?? t.schedule.lessonFallback,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              _MetadataRow(entry: entry),
            ],
          ),
        ),
        Icon(
          Icons.chevron_right,
          color: cs.onPrimaryContainer.withValues(alpha: 0.5),
        ),
      ],
    );
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({required this.entry});

  final ScheduleEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.6);
    final style = theme.textTheme.bodySmall?.copyWith(color: color);

    final parts = <Widget>[
      Icon(Icons.access_time, size: 13, color: color),
      const SizedBox(width: 3),
      Text(entry.timeRange, style: style),
    ];

    if (entry.roomName != null) {
      parts.addAll([
        _dot(color),
        Text(t.schedule.roomPrefix(name: entry.roomName!), style: style),
      ]);
    }

    if (entry.teacherName != null) {
      parts.addAll([
        _dot(color),
        Flexible(
          child: Text(
            entry.teacherName!,
            style: style,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]);
    }

    return Row(children: parts);
  }

  Widget _dot(Color color) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 5),
    child: Text('\u00b7', style: TextStyle(color: color)),
  );
}

class _InactiveLesson extends StatelessWidget {
  const _InactiveLesson({required this.allEnded});

  final bool allEnded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      children: [
        Icon(
          allEnded ? Icons.check_circle_outline : Icons.wb_sunny_outlined,
          size: 28,
          color: cs.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            allEnded ? t.dashboard.allLessonsEnded : t.dashboard.noLessonsToday,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        Icon(
          Icons.chevron_right,
          color: cs.onSurfaceVariant.withValues(alpha: 0.4),
        ),
      ],
    );
  }
}
