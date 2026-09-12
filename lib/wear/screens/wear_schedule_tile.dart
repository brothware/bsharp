import 'package:bsharp/app/providers/dashboard_providers.dart';
import 'package:bsharp/app/providers/schedule_providers.dart';
import 'package:bsharp/domain/schedule_utils.dart';
import 'package:bsharp/domain/timeline_item.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/wear/widgets/wear_tile_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WearScheduleTile extends ConsumerWidget {
  const WearScheduleTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final items = ref.watch(timelineItemsForDateProvider(today));
    final currentLesson = ref.watch(currentLessonProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        WearTileHeader(
          icon: Icons.calendar_today,
          title: '${dayLabelFull(today.weekday)}, ${formatDateShort(today)}',
        ),
        if (items.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.wb_sunny_outlined,
                    size: 28,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t.schedule.noLessons,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: items.take(3).length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isCurrent =
                    item is LessonTimelineItem &&
                    currentLesson.current == item.entry;
                return _WearTimelineRow(item: item, isCurrent: isCurrent);
              },
            ),
          ),
      ],
    );
  }
}

class _WearTimelineRow extends StatelessWidget {
  const _WearTimelineRow({required this.item, required this.isCurrent});

  final TimelineItem item;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = item.displayColor(brightness: theme.brightness);
    final lessonEntry = item is LessonTimelineItem
        ? (item as LessonTimelineItem).entry
        : null;

    return Container(
      key: const Key('lesson-item'),
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isCurrent
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
            : null,
        border: isCurrent
            ? Border.all(color: theme.colorScheme.primary, width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 28,
            decoration: BoxDecoration(
              color: item.isCancelled ? theme.colorScheme.error : color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          if (lessonEntry != null)
            Text(
              '${lessonEntry.number}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            Icon(
              Icons.event,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.displayTitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: item.isCancelled
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.displaySubtitle ?? '',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            item.startTime.substring(0, 5),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
