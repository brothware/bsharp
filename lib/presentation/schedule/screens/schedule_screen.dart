import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bsharp/app/router.dart';
import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/domain/schedule_utils.dart';
import 'package:bsharp/domain/timeline_item.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/schedule/providers/schedule_providers.dart';
import 'package:bsharp/presentation/schedule/widgets/custom_event_card.dart';
import 'package:bsharp/presentation/schedule/widgets/custom_event_detail_sheet.dart';
import 'package:bsharp/presentation/schedule/widgets/lesson_card.dart';
import 'package:bsharp/presentation/schedule/widgets/lesson_detail_sheet.dart';
import 'package:bsharp/presentation/schedule/widgets/linear_day_view.dart';
import 'package:bsharp/presentation/schedule/widgets/week_day_header.dart';

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final weekStart = ref.watch(selectedWeekStartProvider);
    final hasWeekends = ref.watch(hasWeekendEventsProvider);
    final days = hasWeekends ? weekDaysFull(weekStart) : weekDays(weekStart);
    final viewMode = ref.watch(scheduleViewModeProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.customEventCreate),
        tooltip: t.schedule.customEvent.create,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _WeekNavigator(
              weekStart: weekStart,
              viewMode: viewMode,
              onPrevious: () => _changeWeek(ref, -1),
              onNext: () => _changeWeek(ref, 1),
              onToday: () =>
                  ref.read(selectedDateProvider.notifier).state = DateTime.now(),
              onToggleView: () {
                final next = viewMode == ScheduleViewMode.list
                    ? ScheduleViewMode.linear
                    : ScheduleViewMode.list;
                ref.read(scheduleViewModeProvider.notifier).state = next;
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                for (final day in days)
                  Expanded(
                    child: WeekDayHeader(
                      date: day,
                      isSelected: isSameDay(day, selectedDate),
                      onTap: () =>
                          ref.read(selectedDateProvider.notifier).state = day,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${dayLabelFull(selectedDate.weekday)}, '
                '${formatDateFull(selectedDate)}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: viewMode == ScheduleViewMode.list
                ? _DayTimelineList(date: selectedDate)
                : LinearDayView(
                    date: selectedDate,
                    onItemTap: (item) => _showItemDetail(context, item),
                  ),
          ),
        ],
      ),
    );
  }

  void _changeWeek(WidgetRef ref, int direction) {
    final current = ref.read(selectedDateProvider);
    if (direction > 0) {
      final monday = startOfWeek(current);
      ref.read(selectedDateProvider.notifier).state =
          monday.add(const Duration(days: 7));
    } else {
      final friday = endOfWeek(current);
      ref.read(selectedDateProvider.notifier).state =
          friday.subtract(const Duration(days: 7));
    }
  }

  static void _showItemDetail(BuildContext context, TimelineItem item) {
    switch (item) {
      case LessonTimelineItem():
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => LessonDetailSheet(entry: item.entry),
        );
      case CustomEventTimelineItem():
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => CustomEventDetailSheet(
            event: item.event,
            date: item.occurrenceDate,
          ),
        );
    }
  }
}

class _DayTimelineList extends ConsumerWidget {
  const _DayTimelineList({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(timelineItemsForDateProvider(date));

    if (items.isEmpty) {
      return _EmptyDay();
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(syncStatusProvider.notifier).sync(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return switch (item) {
            LessonTimelineItem() => LessonCard(
                entry: item.entry,
                onTap: () => ScheduleScreen._showItemDetail(context, item),
              ),
            CustomEventTimelineItem() => CustomEventCard(
                item: item,
                onTap: () => ScheduleScreen._showItemDetail(context, item),
              ),
          };
        },
      ),
    );
  }
}

class _WeekNavigator extends StatelessWidget {
  const _WeekNavigator({
    required this.weekStart,
    required this.viewMode,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
    required this.onToggleView,
  });

  final DateTime weekStart;
  final ScheduleViewMode viewMode;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final VoidCallback onToggleView;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weekEnd = endOfWeek(weekStart);
    final isCurrentWeek =
        isSameDay(startOfWeek(DateTime.now()), weekStart);

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: onPrevious,
          tooltip: t.schedule.previousWeek,
        ),
        Expanded(
          child: Text(
            '${formatDateShort(weekStart)} - ${formatDateShort(weekEnd)}',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
        ),
        if (!isCurrentWeek)
          TextButton(
            onPressed: onToday,
            child: Text(t.schedule.today),
          ),
        IconButton(
          icon: Icon(
            viewMode == ScheduleViewMode.list
                ? Icons.view_timeline_outlined
                : Icons.list,
          ),
          onPressed: onToggleView,
          tooltip: viewMode == ScheduleViewMode.list
              ? t.schedule.viewTimeline
              : t.schedule.viewList,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: onNext,
          tooltip: t.schedule.nextWeek,
        ),
      ],
    );
  }
}

class _EmptyDay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_busy_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            t.schedule.noEvents,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            t.schedule.noEventsSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
