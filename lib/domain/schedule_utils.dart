import 'dart:ui';

import 'package:bsharp/domain/entities/event.dart';
import 'package:bsharp/l10n/strings.g.dart';

class ScheduleEntry {
  ScheduleEntry({
    required this.event,
    this.subjectName,
    this.teacherName,
    this.roomName,
    this.topic,
    this.changeType,
    this.originalSubjectName,
    this.originalTeacherName,
    this.replacedLessonNumbers = const [],
    this.isReplaced = false,
  });

  final Event event;
  final String? subjectName;
  final String? teacherName;
  final String? roomName;
  final String? topic;
  final ScheduleChangeType? changeType;
  final String? originalSubjectName;
  final String? originalTeacherName;
  final List<int> replacedLessonNumbers;
  final bool isReplaced;

  bool get isCancelled => event.status == 2;
  bool get isSubstitution => event.substitution != 0;
  bool get isLocked => event.locked != 0;

  String get displayLessonNumber {
    if (replacedLessonNumbers.isNotEmpty) {
      final sorted = [...replacedLessonNumbers]..sort();
      final isContiguous =
          sorted.length > 1 && sorted.last - sorted.first == sorted.length - 1;
      return isContiguous
          ? '${sorted.first}-${sorted.last}'
          : sorted.join(', ');
    }
    if (isReplaced) return '-';
    return '${event.number}';
  }

  String get timeRange =>
      '${_formatTime(event.startTime)} - '
      '${_formatTime(event.endTime)}';

  static String _formatTime(String time) {
    final parts = time.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return time;
  }
}

enum ScheduleChangeType { added, cancelled, roomChanged, substitution }

DateTime startOfWeek(DateTime date) {
  final weekday = date.weekday;
  return DateTime(date.year, date.month, date.day - (weekday - 1));
}

DateTime endOfWeek(DateTime date) {
  final monday = startOfWeek(date);
  return monday.add(const Duration(days: 4));
}

DateTime endOfWeekFull(DateTime date) {
  final monday = startOfWeek(date);
  return monday.add(const Duration(days: 6));
}

List<DateTime> weekDays(DateTime date) {
  final monday = startOfWeek(date);
  return List.generate(5, (i) => monday.add(Duration(days: i)));
}

List<DateTime> weekDaysFull(DateTime date) {
  final monday = startOfWeek(date);
  return List.generate(7, (i) => monday.add(Duration(days: i)));
}

String formatDateShort(DateTime dt) {
  return '${dt.day.toString().padLeft(2, '0')}.'
      '${dt.month.toString().padLeft(2, '0')}';
}

String formatDateFull(DateTime dt) {
  return '${dt.day.toString().padLeft(2, '0')}.'
      '${dt.month.toString().padLeft(2, '0')}.'
      '${dt.year}';
}

String dayLabel(int weekday) {
  return switch (weekday) {
    1 => t.schedule.dayShort.mon,
    2 => t.schedule.dayShort.tue,
    3 => t.schedule.dayShort.wed,
    4 => t.schedule.dayShort.thu,
    5 => t.schedule.dayShort.fri,
    6 => t.schedule.dayShort.sat,
    7 => t.schedule.dayShort.sun,
    _ => '',
  };
}

String dayLabelFull(int weekday) {
  return switch (weekday) {
    1 => t.schedule.dayFull.mon,
    2 => t.schedule.dayFull.tue,
    3 => t.schedule.dayFull.wed,
    4 => t.schedule.dayFull.thu,
    5 => t.schedule.dayFull.fri,
    6 => t.schedule.dayFull.sat,
    7 => t.schedule.dayFull.sun,
    _ => '',
  };
}

Color subjectColor(int subjectId) {
  const palette = [
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFFFF9800),
    Color(0xFF9C27B0),
    Color(0xFFE91E63),
    Color(0xFF009688),
    Color(0xFF795548),
    Color(0xFF607D8B),
    Color(0xFFFF5722),
    Color(0xFF3F51B5),
    Color(0xFFCDDC39),
    Color(0xFF00BCD4),
  ];
  return palette[subjectId.abs() % palette.length];
}

class ReplacementMapping {
  const ReplacementMapping({
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

ReplacementMapping buildReplacementMapping(
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

  return ReplacementMapping(
    replacedIds: replacedIds,
    replacementIds: replacementIds,
    replacedToReplacement: replacedToReplacement,
    replacementToOriginals: replacementToOriginals,
    directSubstitutionOriginals: directSubstitutionOriginals,
    directSubstitutionReplacements: directSubstitutionReplacements,
  );
}

bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

DateTime nextScheduleDay(DateTime date, {required bool includeWeekends}) {
  final next = date.add(const Duration(days: 1));
  if (includeWeekends || next.weekday <= DateTime.friday) return next;
  return DateTime(
    next.year,
    next.month,
    next.day + (DateTime.monday - next.weekday + 7) % 7,
  );
}

DateTime previousScheduleDay(DateTime date, {required bool includeWeekends}) {
  final prev = date.subtract(const Duration(days: 1));
  if (includeWeekends || prev.weekday <= DateTime.friday) return prev;
  return DateTime(
    prev.year,
    prev.month,
    prev.day - (prev.weekday - DateTime.friday),
  );
}
