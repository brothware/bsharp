import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bsharp/domain/entities/event.dart';
import 'package:bsharp/domain/entities/room.dart';
import 'package:bsharp/domain/entities/subject.dart';
import 'package:bsharp/domain/entities/teacher.dart';
import 'package:bsharp/domain/schedule_utils.dart';
import 'package:bsharp/domain/translation_utils.dart';
import 'package:bsharp/presentation/grades/providers/grades_providers.dart';

final eventsProvider = StateProvider<List<Event>>((ref) => []);

final eventTypesProvider = StateProvider<List<EventType>>((ref) => []);

final eventTypeTeachersProvider =
    StateProvider<List<EventTypeTeacher>>((ref) => []);

final eventSubjectsProvider = StateProvider<List<EventSubject>>((ref) => []);

final eventTypeTermsProvider =
    StateProvider<List<EventTypeTerm>>((ref) => []);

final roomsProvider = StateProvider<List<Room>>((ref) => []);

final selectedDateProvider = StateProvider<DateTime>(
  (ref) => DateTime.now(),
);

final selectedWeekStartProvider = Provider<DateTime>((ref) {
  final date = ref.watch(selectedDateProvider);
  return startOfWeek(date);
});

final eventsForDateProvider =
    Provider.family<List<Event>, DateTime>((ref, date) {
  final events = ref.watch(eventsProvider);
  return events.where((e) => isSameDay(e.date, date)).toList()
    ..sort((a, b) => a.number.compareTo(b.number));
});

final scheduleEntriesForDateProvider =
    Provider.family<List<ScheduleEntry>, DateTime>((ref, date) {
  final events = ref.watch(eventsForDateProvider(date));
  final eventTypes = ref.watch(eventTypesProvider);
  final eventTypeTeachers = ref.watch(eventTypeTeachersProvider);
  final eventSubs = ref.watch(eventSubjectsProvider);
  final subjects = ref.watch(subjectsProvider);
  final teachers = ref.watch(teachersProvider);
  final rooms = ref.watch(roomsProvider);

  final eventTypeMap = {for (final et in eventTypes) et.id: et};
  final subjectMap = {for (final s in subjects) s.id: s};
  final teacherMap = {for (final t in teachers) t.id: t};
  final roomMap = {for (final r in rooms) r.id: r};

  return events.map((event) {
    final eventType = eventTypeMap[event.eventTypesId];
    final rawSubject =
        eventType != null ? subjectMap[eventType.subjectsId]?.name : null;
    final subjectName =
        rawSubject != null ? translateSubjectName(rawSubject) : null;

    final teacherLink = eventTypeTeachers
        .where((ett) => ett.eventTypesId == event.eventTypesId);
    final teacher = teacherLink.isNotEmpty
        ? teacherMap[teacherLink.first.teachersId]
        : null;
    final teacherName =
        teacher != null ? '${teacher.name} ${teacher.surname}' : null;

    final roomName =
        event.roomsId != null ? roomMap[event.roomsId]?.name : null;

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

    return ScheduleEntry(
      event: event,
      subjectName: subjectName,
      teacherName: teacherName,
      roomName: roomName,
      topic: topic.isNotEmpty ? topic : null,
      changeType: changeType,
    );
  }).toList();
});

final weekEntriesProvider =
    Provider<Map<DateTime, List<ScheduleEntry>>>((ref) {
  final weekStart = ref.watch(selectedWeekStartProvider);
  final days = weekDays(weekStart);
  return {
    for (final day in days)
      day: ref.watch(scheduleEntriesForDateProvider(day)),
  };
});
