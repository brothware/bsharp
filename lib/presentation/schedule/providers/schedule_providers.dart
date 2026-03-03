import 'package:bsharp/domain/entities/event.dart';
import 'package:bsharp/domain/entities/room.dart';
import 'package:bsharp/domain/schedule_utils.dart';
import 'package:bsharp/domain/timeline_item.dart';
import 'package:bsharp/domain/translation_utils.dart';
import 'package:bsharp/presentation/grades/providers/grades_providers.dart';
import 'package:bsharp/presentation/schedule/providers/custom_event_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ScheduleViewMode { list, linear }

final scheduleViewModeProvider = StateProvider<ScheduleViewMode>(
  (ref) => ScheduleViewMode.list,
);

final eventsProvider = StateProvider<List<Event>>((ref) => []);

final eventTypesProvider = StateProvider<List<EventType>>((ref) => []);

final eventTypeTeachersProvider = StateProvider<List<EventTypeTeacher>>(
  (ref) => [],
);

final eventSubjectsProvider = StateProvider<List<EventSubject>>((ref) => []);

final eventEventsProvider = StateProvider<List<EventEvent>>((ref) => []);

final eventTypeTermsProvider = StateProvider<List<EventTypeTerm>>((ref) => []);

final roomsProvider = StateProvider<List<Room>>((ref) => []);

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final selectedWeekStartProvider = Provider<DateTime>((ref) {
  final date = ref.watch(selectedDateProvider);
  return startOfWeek(date);
});

final eventsForDateProvider = Provider.family<List<Event>, DateTime>((
  ref,
  date,
) {
  final events = ref.watch(eventsProvider);
  final eventEvents = ref.watch(eventEventsProvider);
  final replacedIds = {for (final ee in eventEvents) ee.events1Id};
  return events
      .where((e) => isSameDay(e.date, date) && !replacedIds.contains(e.id))
      .toList()
    ..sort((a, b) => a.number.compareTo(b.number));
});

final scheduleEntriesForDateProvider =
    Provider.family<List<ScheduleEntry>, DateTime>((ref, date) {
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
    });

final weekEntriesProvider = Provider<Map<DateTime, List<ScheduleEntry>>>((ref) {
  final weekStart = ref.watch(selectedWeekStartProvider);
  final days = weekDays(weekStart);
  return {
    for (final day in days) day: ref.watch(scheduleEntriesForDateProvider(day)),
  };
});

int _timeToMinutes(String time) {
  final parts = time.split(':');
  if (parts.length < 2) return 0;
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

final timelineItemsForDateProvider =
    Provider.family<List<TimelineItem>, DateTime>((ref, date) {
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
            (a, b) => _timeToMinutes(
              a.startTime,
            ).compareTo(_timeToMinutes(b.startTime)),
          );

      return items;
    });

final hasWeekendEventsProvider = Provider<bool>((ref) {
  final weekStart = ref.watch(selectedWeekStartProvider);
  final saturday = weekStart.add(const Duration(days: 5));
  final sunday = weekStart.add(const Duration(days: 6));
  final satItems = ref.watch(timelineItemsForDateProvider(saturday));
  final sunItems = ref.watch(timelineItemsForDateProvider(sunday));
  return satItems.isNotEmpty || sunItems.isNotEmpty;
});
