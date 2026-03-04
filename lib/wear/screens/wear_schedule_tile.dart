import 'package:bsharp/domain/schedule_utils.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/schedule/providers/schedule_providers.dart';
import 'package:bsharp/wear/screens/wear_schedule_detail_screen.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:bsharp/wear/widgets/wear_forward_swipe.dart';
import 'package:bsharp/wear/widgets/wear_tile_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WearScheduleTile extends ConsumerWidget {
  const WearScheduleTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shape = ref.watch(wearScreenShapeProvider).requireValue;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entries = ref.watch(scheduleEntriesForDateProvider(today));
    final theme = Theme.of(context);

    return WearForwardSwipe(
      onTriggered: () => _openDetail(context),
      child: Column(
        children: [
          WearTileHeader(
            icon: Icons.calendar_today,
            title: '${dayLabelFull(today.weekday)}, ${formatDateShort(today)}',
          ),
          if (entries.isEmpty)
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: () => _openDetail(context),
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
                      const SizedBox(height: 8),
                      Text(
                        t.schedule.browseDays,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  8,
                  0,
                  8,
                  wearListBottomInset(shape),
                ),
                itemCount: entries.take(3).length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final isCurrent = _isCurrentLesson(entry, now);
                  return _WearLessonItem(entry: entry, isCurrent: isCurrent);
                },
              ),
            ),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const WearScheduleDetailScreen()),
    );
  }

  bool _isCurrentLesson(ScheduleEntry entry, DateTime now) {
    final timeParts = entry.event.startTime.split(':');
    final endParts = entry.event.endTime.split(':');
    if (timeParts.length < 2 || endParts.length < 2) return false;

    final start = DateTime(
      now.year,
      now.month,
      now.day,
      int.tryParse(timeParts[0]) ?? 0,
      int.tryParse(timeParts[1]) ?? 0,
    );
    final end = DateTime(
      now.year,
      now.month,
      now.day,
      int.tryParse(endParts[0]) ?? 0,
      int.tryParse(endParts[1]) ?? 0,
    );

    return now.isAfter(start) && now.isBefore(end);
  }
}

class _WearLessonItem extends StatelessWidget {
  const _WearLessonItem({required this.entry, required this.isCurrent});

  final ScheduleEntry entry;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sColor = entry.event.eventTypesId > 0
        ? subjectColor(entry.event.eventTypesId)
        : theme.colorScheme.primary;

    return Container(
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
              color: entry.isCancelled ? theme.colorScheme.error : sColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${entry.event.number}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.subjectName ??
                      '${t.schedule.lessonFallback} ${entry.event.number}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: entry.isCancelled
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  entry.roomName ?? '',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            entry.event.startTime.substring(0, 5),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
