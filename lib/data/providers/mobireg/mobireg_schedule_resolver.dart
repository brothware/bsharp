import 'package:bsharp/data/services/mobireg_translations.dart';
import 'package:bsharp/domain/entities/event.dart';
import 'package:bsharp/domain/entities/resolved_event.dart';
import 'package:bsharp/domain/entities/room.dart';
import 'package:bsharp/domain/entities/subject.dart';
import 'package:bsharp/domain/entities/teacher.dart';
import 'package:bsharp/domain/message_utils.dart';

class MobiregScheduleResolver {
  List<ResolvedEvent> resolve({
    required List<Event> events,
    required List<EventType> eventTypes,
    required List<EventTypeTeacher> eventTypeTeachers,
    required List<EventSubject> eventSubjects,
    required List<EventEvent> eventEvents,
    required List<Subject> subjects,
    required List<Teacher> teachers,
    required List<Room> rooms,
  }) {
    final eventTypeMap = {for (final et in eventTypes) et.id: et};
    final subjectMap = {for (final s in subjects) s.id: s};
    final teacherMap = {for (final t in teachers) t.id: t};
    final roomMap = {for (final r in rooms) r.id: r};
    final eventMap = {for (final e in events) e.id: e};

    final mapping = _buildReplacementMapping(eventEvents, eventMap);

    String? resolveSubject(int eventTypesId) {
      final et = eventTypeMap[eventTypesId];
      final raw = et != null ? subjectMap[et.subjectsId]?.name : null;
      return raw != null ? normalizeMobiregSubjectName(raw) : null;
    }

    int? resolveSubjectId(int eventTypesId) {
      final et = eventTypeMap[eventTypesId];
      return et?.subjectsId;
    }

    String? resolveTeacher(int eventTypesId) {
      final link = eventTypeTeachers.where(
        (ett) => ett.eventTypesId == eventTypesId,
      );
      if (link.isEmpty) return null;
      final t = teacherMap[link.first.teachersId];
      return t != null ? '${t.name} ${t.surname}' : null;
    }

    return events
        .map((event) {
          final subjectName = resolveSubject(event.eventTypesId);
          final subjectId = resolveSubjectId(event.eventTypesId);
          final teacherName = resolveTeacher(event.eventTypesId);
          final roomName = event.roomsId != null
              ? roomMap[event.roomsId]?.name
              : null;

          final topic = eventSubjects
              .where((es) => es.eventsId == event.id)
              .map((es) => es.content)
              .join(', ');

          final isReplaced = mapping.replacedIds.contains(event.id);

          var isCancelled = event.status == 2;
          var isSubstitution = false;

          if (isReplaced) {
            isCancelled = true;
          } else if (mapping.replacementToOriginals.containsKey(event.id) ||
              event.substitution == 2) {
            isSubstitution = true;
          }

          String? originalSubjectName;
          String? originalTeacherName;
          var replacedLessonNumbers = const <int>[];

          final originalIds = mapping.replacementToOriginals[event.id];
          if (originalIds != null) {
            replacedLessonNumbers =
                originalIds
                    .map((id) => eventMap[id]?.number ?? 0)
                    .where((n) => n > 0)
                    .toList()
                  ..sort();

            final firstOrigId = originalIds.first;
            final origEvent = eventMap[firstOrigId];
            if (origEvent != null) {
              originalSubjectName = resolveSubject(origEvent.eventTypesId);
              originalTeacherName = resolveTeacher(origEvent.eventTypesId);
            }
          }

          final cleanEventName = event.name != null
              ? stripHtml(event.name!).trim()
              : null;
          final useEventName =
              originalIds != null &&
              !mapping.directSubstitutionReplacements.contains(event.id) &&
              cleanEventName?.isNotEmpty == true;
          final resolvedSubjectName = originalIds != null
              ? ((useEventName ? cleanEventName : null) ??
                    subjectName ??
                    originalSubjectName)
              : subjectName;

          return ResolvedEvent(
            id: event.id,
            date: event.date,
            number: event.number,
            startTime: event.startTime,
            endTime: event.endTime,
            subjectName: resolvedSubjectName,
            teacherName: teacherName,
            roomName: roomName,
            topic: topic.isNotEmpty ? topic : null,
            subjectId: subjectId,
            isCancelled: isCancelled,
            isSubstitution: isSubstitution,
            isLocked: event.locked != 0,
            originalSubjectName: originalSubjectName,
            originalTeacherName: originalTeacherName,
            replacedLessonNumbers: replacedLessonNumbers,
            isReplaced: isReplaced,
            replacedByEventId: isReplaced
                ? mapping.replacedToReplacement[event.id]
                : null,
            eventName: cleanEventName,
          );
        })
        .where(
          (re) => !mapping.directSubstitutionOriginals.contains(re.id),
        )
        .toList();
  }
}

class _ReplacementMapping {
  const _ReplacementMapping({
    required this.replacedIds,
    required this.replacementIds,
    required this.replacedToReplacement,
    required this.replacementToOriginals,
    this.directSubstitutionOriginals = const {},
    this.directSubstitutionReplacements = const {},
  });

  final Set<int> replacedIds;
  final Set<int> replacementIds;
  final Map<int, int> replacedToReplacement;
  final Map<int, List<int>> replacementToOriginals;
  final Set<int> directSubstitutionOriginals;
  final Set<int> directSubstitutionReplacements;
}

_ReplacementMapping _buildReplacementMapping(
  List<EventEvent> eventEvents,
  Map<int, Event> eventMap,
) {
  final replacedIds = <int>{};
  final replacementIds = <int>{};
  final replacedToReplacement = <int, int>{};
  final replacementToOriginals = <int, List<int>>{};
  final directSubstitutionOriginals = <int>{};
  final directSubstitutionReplacements = <int>{};

  for (final ee in eventEvents) {
    final e1 = eventMap[ee.events1Id];
    final e2 = eventMap[ee.events2Id];
    if (e1 == null || e2 == null) continue;

    int originalId;
    int replacementId;

    if (e1.substitution == 1 && e2.substitution == 2) {
      originalId = ee.events1Id;
      replacementId = ee.events2Id;
    } else {
      originalId = ee.events2Id;
      replacementId = ee.events1Id;
    }

    replacedIds.add(originalId);
    replacementIds.add(replacementId);
    replacedToReplacement[originalId] = replacementId;
    replacementToOriginals.putIfAbsent(replacementId, () => []).add(originalId);
  }

  for (final entry in replacementToOriginals.entries) {
    if (entry.value.length != 1) continue;
    final replacementId = entry.key;
    final originalId = entry.value.first;
    final replacement = eventMap[replacementId];
    final original = eventMap[originalId];
    if (replacement != null &&
        original != null &&
        original.substitution == 1 &&
        replacement.substitution == 2) {
      directSubstitutionOriginals.add(originalId);
      directSubstitutionReplacements.add(replacementId);
    }
  }

  return _ReplacementMapping(
    replacedIds: replacedIds,
    replacementIds: replacementIds,
    replacedToReplacement: replacedToReplacement,
    replacementToOriginals: replacementToOriginals,
    directSubstitutionOriginals: directSubstitutionOriginals,
    directSubstitutionReplacements: directSubstitutionReplacements,
  );
}
