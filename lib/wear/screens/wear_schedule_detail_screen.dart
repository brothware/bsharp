import 'package:bsharp/app/providers/schedule_providers.dart';
import 'package:bsharp/domain/schedule_utils.dart';
import 'package:bsharp/domain/timeline_item.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/wear/widgets/wear_period_selector.dart';
import 'package:bsharp/wear/widgets/wear_scaffold.dart';
import 'package:bsharp/wear/widgets/wear_swipe_dismiss.dart';
import 'package:bsharp/wear/widgets/wear_vertical_overscroll_pager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wear_os_scrollbar/wear_os_scrollbar.dart';

class WearScheduleDetailScreen extends ConsumerStatefulWidget {
  const WearScheduleDetailScreen({super.key});

  @override
  ConsumerState<WearScheduleDetailScreen> createState() =>
      _WearScheduleDetailScreenState();
}

class _WearScheduleDetailScreenState
    extends ConsumerState<WearScheduleDetailScreen> {
  late DateTime _selectedDate;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _previousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
  }

  void _nextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(timelineItemsForDateProvider(_selectedDate));
    final theme = Theme.of(context);

    return WearSwipeDismiss(
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: WearScaffold(
          child: Column(
            children: [
              WearPeriodSelector(
                label: formatDateShort(_selectedDate),
                subLabel: dayLabelFull(_selectedDate.weekday),
                onPrevious: _previousDay,
                onNext: _nextDay,
              ),
              const SizedBox(height: 4),
              Expanded(
                child: WearOsScrollbar(
                  controller: _scrollController,
                  child: WearVerticalOverscrollPager(
                    onPrevious: _previousDay,
                    onNext: _nextDay,
                    child: items.isEmpty
                        ? ListView(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            children: [
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 32),
                                  child: Text(
                                    t.schedule.noLessons,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Scrollbar(
                            controller: _scrollController,
                            child: ListView.builder(
                              controller: _scrollController,
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                              itemCount: items.length,
                              itemBuilder: (context, index) =>
                                  _WearDetailTimelineItem(item: items[index]),
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WearDetailTimelineItem extends StatelessWidget {
  const _WearDetailTimelineItem({required this.item});

  final TimelineItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = item.displayColor(brightness: theme.brightness);
    final lessonEntry = item is LessonTimelineItem
        ? (item as LessonTimelineItem).entry
        : null;
    final timeRange =
        '${item.startTime.substring(0, 5)} - '
        '${item.endTime.substring(0, 5)}';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: lessonEntry?.changeType != null
            ? theme.colorScheme.errorContainer.withValues(alpha: 0.2)
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 28,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: item.isCancelled ? theme.colorScheme.error : color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          if (lessonEntry == null)
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 4),
              child: Icon(
                Icons.event,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.displayTitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    decoration: item.isCancelled
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.displaySubtitle != null)
                  Text(
                    item.displaySubtitle!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  timeRange,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (lessonEntry?.topic != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      lessonEntry!.topic!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (lessonEntry?.changeType != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        scheduleChangeLabel(lessonEntry!.changeType!),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
