import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/domain/schedule_utils.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/schedule/providers/schedule_providers.dart';
import 'package:bsharp/presentation/schedule/widgets/lesson_card.dart';
import 'package:bsharp/presentation/schedule/widgets/lesson_detail_sheet.dart';
import 'package:bsharp/presentation/schedule/widgets/week_day_header.dart';

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final weekStart = ref.watch(selectedWeekStartProvider);
    final days = weekDays(weekStart);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: _WeekNavigator(
            weekStart: weekStart,
            onPrevious: () => _changeWeek(ref, -1),
            onNext: () => _changeWeek(ref, 1),
            onToday: () =>
                ref.read(selectedDateProvider.notifier).state = DateTime.now(),
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
          child: _DayLessonList(date: selectedDate),
        ),
      ],
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
}

class _DayLessonList extends ConsumerWidget {
  const _DayLessonList({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(scheduleEntriesForDateProvider(date));

    if (entries.isEmpty) {
      return _EmptyDay();
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(syncStatusProvider.notifier).sync(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          return LessonCard(
            entry: entry,
            onTap: () => _showDetail(context, entry),
          );
        },
      ),
    );
  }

  void _showDetail(BuildContext context, ScheduleEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LessonDetailSheet(entry: entry),
    );
  }
}

class _WeekNavigator extends StatelessWidget {
  const _WeekNavigator({
    required this.weekStart,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  final DateTime weekStart;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

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
            t.schedule.noLessons,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            t.schedule.noLessonsSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
