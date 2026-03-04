import 'package:bsharp/domain/entities/event.dart';
import 'package:bsharp/domain/entities/room.dart';
import 'package:bsharp/domain/schedule_utils.dart';
import 'package:bsharp/domain/timeline_item.dart';
import 'package:bsharp/domain/translation_utils.dart';
import 'package:bsharp/presentation/grades/providers/grades_providers.dart';
import 'package:bsharp/presentation/schedule/providers/custom_event_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'schedule_providers.g.dart';

enum ScheduleViewMode { list, linear }

class ScheduleViewModeNotifier extends Notifier<ScheduleViewMode> {
  @override
  ScheduleViewMode build() => ScheduleViewMode.list;
  ScheduleViewMode get value => state;
  set value(ScheduleViewMode v) => state = v;
}

final scheduleViewModeProvider =
    NotifierProvider<ScheduleViewModeNotifier, ScheduleViewMode>(
      ScheduleViewModeNotifier.new,
    );

@Riverpod(keepAlive: true)
class Events extends _$Events {
  @override
  List<Event> build() => [];
  List<Event> get value => state;
  set value(List<Event> v) => state = v;
}

@Riverpod(keepAlive: true)
class EventTypes extends _$EventTypes {
  @override
  List<EventType> build() => [];
  List<EventType> get value => state;
  set value(List<EventType> v) => state = v;
}

@Riverpod(keepAlive: true)
class EventTypeTeachers extends _$EventTypeTeachers {
  @override
  List<EventTypeTeacher> build() => [];
  List<EventTypeTeacher> get value => state;
  set value(List<EventTypeTeacher> v) => state = v;
}

@Riverpod(keepAlive: true)
class EventSubjects extends _$EventSubjects {
  @override
  List<EventSubject> build() => [];
  List<EventSubject> get value => state;
  set value(List<EventSubject> v) => state = v;
}

@Riverpod(keepAlive: true)
class EventEvents extends _$EventEvents {
  @override
  List<EventEvent> build() => [];
  List<EventEvent> get value => state;
  set value(List<EventEvent> v) => state = v;
}

@Riverpod(keepAlive: true)
class EventTypeTerms extends _$EventTypeTerms {
  @override
  List<EventTypeTerm> build() => [];
  List<EventTypeTerm> get value => state;
  set value(List<EventTypeTerm> v) => state = v;
}

@Riverpod(keepAlive: true)
class Rooms extends _$Rooms {
  @override
  List<Room> build() => [];
  List<Room> get value => state;
  set value(List<Room> v) => state = v;
}

@Riverpod(keepAlive: true)
class SelectedDate extends _$SelectedDate {
  @override
  DateTime build() => DateTime.now();
  DateTime get value => state;
  set value(DateTime v) => state = v;
}

@Riverpod(keepAlive: true)
DateTime selectedWeekStart(Ref ref) {
  final date = ref.watch(selectedDateProvider);
  return startOfWeek(date);
}

@Riverpod(keepAlive: true)
List<Event> eventsForDate(Ref ref, DateTime date) {
  final events = ref.watch(eventsProvider);
  final eventEvents = ref.watch(eventEventsProvider);
  final replacedIds = {for (final ee in eventEvents) ee.events1Id};
  return events
      .where((e) => isSameDay(e.date, date) && !replacedIds.contains(e.id))
      .toList()
    ..sort((a, b) => a.number.compareTo(b.number));
}

@Riverpod(keepAlive: true)
List<ScheduleEntry> scheduleEntriesForDate(Ref ref, DateTime date) {
  final events = ref.watch(eventsForDateProvider(date));
  final allEvents = ref.watch(eventsProvider);
  final eventTypes = ref.watch(eventTypesProvider);
  final eventTypeTeachers = ref.watch(eventTypeTeachersProvider);
  final eventSubs = ref.watch(eventSubjectsProvider);
  final eventEvents = ref.watch(eventEventsProvider);
  final subjects = ref.watch(subjectsProvider);
  final teachers = ref.watch(teachersProvider);
  final rooms = ref.watch(roomsProvider);

  final eventTypeMap = {for (final et in eventTypes) et.id: et};
  final subjectMap = {for (final s in subjects) s.id: s};
  final teacherMap = {for (final t in teachers) t.id: t};
  final roomMap = {for (final r in rooms) r.id: r};
  final allEventsMap = {for (final e in allEvents) e.id: e};
  final originalIdMap = {
    for (final ee in eventEvents) ee.events2Id: ee.events1Id,
  };

  String? resolveSubject(int eventTypesId) {
    final et = eventTypeMap[eventTypesId];
    final raw = et != null ? subjectMap[et.subjectsId]?.name : null;
    return raw != null ? translateSubjectName(raw) : null;
  }

  String? resolveTeacher(int eventTypesId) {
    final link = eventTypeTeachers.where(
      (ett) => ett.eventTypesId == eventTypesId,
    );
    if (link.isEmpty) return null;
    final t = teacherMap[link.first.teachersId];
    return t != null ? '${t.name} ${t.surname}' : null;
  }

  return events.map((event) {
    final subjectName = resolveSubject(event.eventTypesId);
    final teacherName = resolveTeacher(event.eventTypesId);

    final roomName = event.roomsId != null
        ? roomMap[event.roomsId]?.name
        : null;

    final topic = eventSubs
        .where((es) => es.eventsId == event.id)
        .map((es) => es.content)
        .join(', ');

    ScheduleChangeType? changeType;
    if (event.status == 2) {
      changeType = ScheduleChangeType.cancelled;
    } else if (event.substitution != 0) {
      changeType = ScheduleChangeType.substitution;
    }

    String? originalSubjectName;
    String? originalTeacherName;
    if (event.substitution == 2) {
      final origId = originalIdMap[event.id];
      final origEvent = origId != null ? allEventsMap[origId] : null;
      if (origEvent != null) {
        originalSubjectName = resolveSubject(origEvent.eventTypesId);
        originalTeacherName = resolveTeacher(origEvent.eventTypesId);
      }
    }

    return ScheduleEntry(
      event: event,
      subjectName: subjectName,
      teacherName: teacherName,
      roomName: roomName,
      topic: topic.isNotEmpty ? topic : null,
      changeType: changeType,
      originalSubjectName: originalSubjectName,
      originalTeacherName: originalTeacherName,
    );
  }).toList();
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
