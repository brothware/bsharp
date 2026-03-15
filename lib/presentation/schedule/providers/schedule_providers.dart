import 'dart:async';

import 'package:bsharp/domain/entities/resolved_event.dart';
import 'package:bsharp/domain/schedule_utils.dart';
import 'package:bsharp/domain/timeline_item.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:bsharp/presentation/schedule/providers/custom_event_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'schedule_providers.g.dart';

enum ScheduleViewMode { list, linear }

class ScheduleViewModeNotifier extends Notifier<ScheduleViewMode> {
  static const _key = 'schedule_view_mode';

  @override
  ScheduleViewMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final stored = prefs.getString(_key);
    return stored == 'linear' ? ScheduleViewMode.linear : ScheduleViewMode.list;
  }

  ScheduleViewMode get value => state;

  set value(ScheduleViewMode v) {
    unawaited(
      ref
          .read(sharedPreferencesProvider)
          .setString(_key, v == ScheduleViewMode.linear ? 'linear' : 'list'),
    );
    state = v;
  }
}

final scheduleViewModeProvider =
    NotifierProvider<ScheduleViewModeNotifier, ScheduleViewMode>(
      ScheduleViewModeNotifier.new,
    );

@Riverpod(keepAlive: true)
class ResolvedEvents extends _$ResolvedEvents {
  @override
  List<ResolvedEvent> build() => [];
  List<ResolvedEvent> get value => state;
  set value(List<ResolvedEvent> v) => state = v;
}

@Riverpod(keepAlive: true)
class SelectedDate extends _$SelectedDate {
  @override
  DateTime build() => _snapToWeekday(DateTime.now());
  DateTime get value => state;
  set value(DateTime v) => state = _snapToWeekday(v);

  static DateTime _snapToWeekday(DateTime date) {
    if (date.weekday == DateTime.saturday) {
      return date.subtract(const Duration(days: 1));
    }
    if (date.weekday == DateTime.sunday) {
      return date.subtract(const Duration(days: 2));
    }
    return date;
  }
}

@Riverpod(keepAlive: true)
DateTime selectedWeekStart(Ref ref) {
  final date = ref.watch(selectedDateProvider);
  return startOfWeek(date);
}

@Riverpod(keepAlive: true)
List<ScheduleEntry> scheduleEntriesForDate(Ref ref, DateTime date) {
  final resolved = ref.watch(resolvedEventsProvider);
  return resolved
      .where((e) => isSameDay(e.date, date))
      .map(ScheduleEntry.fromResolved)
      .toList()
    ..sort((a, b) {
      final aKey = a.replacedLessonNumbers.isNotEmpty
          ? a.replacedLessonNumbers.reduce((x, y) => x > y ? x : y) + 0.5
          : a.number.toDouble();
      final bKey = b.replacedLessonNumbers.isNotEmpty
          ? b.replacedLessonNumbers.reduce((x, y) => x > y ? x : y) + 0.5
          : b.number.toDouble();
      return aKey.compareTo(bKey);
    });
}

@Riverpod(keepAlive: true)
Map<DateTime, List<ScheduleEntry>> weekEntries(Ref ref) {
  final weekStart = ref.watch(selectedWeekStartProvider);
  final days = weekDays(weekStart);
  return {
    for (final day in days) day: ref.watch(scheduleEntriesForDateProvider(day)),
  };
}

int _timeToMinutes(String time) {
  final parts = time.split(':');
  if (parts.length < 2) return 0;
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

@Riverpod(keepAlive: true)
List<TimelineItem> timelineItemsForDate(Ref ref, DateTime date) {
  final entries = ref.watch(scheduleEntriesForDateProvider(date));
  final customEvents = ref.watch(customEventsProvider);
  final occurrences = ref.watch(customEventOccurrencesProvider);

  final eventMap = {for (final e in customEvents) e.id: e};

  final items =
      <TimelineItem>[
        for (final entry in entries) LessonTimelineItem(entry: entry),
        for (final occ in occurrences)
          if (isSameDay(occ.date, date) &&
              eventMap.containsKey(occ.customEventId))
            CustomEventTimelineItem(
              event: eventMap[occ.customEventId]!,
              occurrenceDate: occ.date,
            ),
      ]..sort(
        (a, b) =>
            _timeToMinutes(a.startTime).compareTo(_timeToMinutes(b.startTime)),
      );

  return items;
}

@Riverpod(keepAlive: true)
bool hasWeekendEvents(Ref ref) {
  final weekStart = ref.watch(selectedWeekStartProvider);
  final saturday = weekStart.add(const Duration(days: 5));
  final sunday = weekStart.add(const Duration(days: 6));
  final satItems = ref.watch(timelineItemsForDateProvider(saturday));
  final sunItems = ref.watch(timelineItemsForDateProvider(sunday));
  return satItems.isNotEmpty || sunItems.isNotEmpty;
}
