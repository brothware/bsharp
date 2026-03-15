import 'dart:ui';

import 'package:bsharp/domain/entities/attendance.dart';
import 'package:bsharp/domain/entities/resolved_event.dart';
import 'package:bsharp/domain/entities/sync_action.dart';
import 'package:bsharp/domain/translation_utils.dart';

class AttendanceDay {
  AttendanceDay({required this.date, required this.entries});

  final DateTime date;
  final List<AttendanceEntry> entries;

  int get presentCount => entries
      .where(
        (e) =>
            e.type.countAs == AttendanceCountAs.present ||
            e.type.countAs == AttendanceCountAs.other,
      )
      .length;

  int get absentCount => entries
      .where(
        (e) =>
            e.type.countAs == AttendanceCountAs.absent ||
            e.type.countAs == AttendanceCountAs.late,
      )
      .length;

  bool get hasAbsences => absentCount > 0;
  bool get allPresent => entries.isNotEmpty && absentCount == 0;

  bool get _hasAbsentEntries =>
      entries.any((e) => e.type.countAs == AttendanceCountAs.absent);

  bool get _hasLateEntries =>
      entries.any((e) => e.type.countAs == AttendanceCountAs.late);

  bool get _hasUnexcused => entries.any(
    (e) =>
        (e.type.countAs == AttendanceCountAs.absent ||
            e.type.countAs == AttendanceCountAs.late) &&
        e.type.excuseStatus == AttendanceExcuseStatus.unexcused,
  );

  AttendanceDayStatus get status {
    if (entries.isEmpty) return AttendanceDayStatus.noData;
    if (allPresent) return AttendanceDayStatus.present;
    if (_hasUnexcused) return AttendanceDayStatus.unexcused;
    if (presentCount == 0 && _hasLateEntries && !_hasAbsentEntries) {
      return AttendanceDayStatus.late;
    }
    if (presentCount == 0 && _hasAbsentEntries) {
      return AttendanceDayStatus.excused;
    }
    return AttendanceDayStatus.mixed;
  }
}

class AttendanceEntry {
  AttendanceEntry({
    required this.attendance,
    required this.type,
    this.resolvedEvent,
    this.subjectName,
    this.displayLessonNumber,
  });

  final Attendance attendance;
  final AttendanceType type;
  final ResolvedEvent? resolvedEvent;
  final String? subjectName;
  final String? displayLessonNumber;
}

enum AttendanceDayStatus { present, excused, unexcused, late, mixed, noData }

class AttendanceStats {
  AttendanceStats({
    required this.totalLessons,
    required this.presentCount,
    required this.absentCount,
    required this.typeCounts,
  });

  final int totalLessons;
  final int presentCount;
  final int absentCount;
  final Map<String, int> typeCounts;

  double get presentPercent =>
      totalLessons > 0 ? (presentCount / totalLessons) * 100 : 0;

  double get absentPercent =>
      totalLessons > 0 ? (absentCount / totalLessons) * 100 : 0;
}

Color attendanceStatusColor(AttendanceDayStatus status) {
  return switch (status) {
    AttendanceDayStatus.present => const Color(0xFF4CAF50),
    AttendanceDayStatus.excused => const Color(0xFF42A5F5),
    AttendanceDayStatus.unexcused => const Color(0xFFF44336),
    AttendanceDayStatus.late => const Color(0xFFFFA726),
    AttendanceDayStatus.mixed => const Color(0xFFFFA726),
    AttendanceDayStatus.noData => const Color(0xFFBDBDBD),
  };
}

Color attendanceTypeColor(
  AttendanceCountAs countAs, [
  AttendanceExcuseStatus? excuseStatus,
]) {
  if ((countAs == AttendanceCountAs.absent ||
          countAs == AttendanceCountAs.late) &&
      excuseStatus == AttendanceExcuseStatus.excused) {
    return const Color(0xFF42A5F5);
  }
  return switch (countAs) {
    AttendanceCountAs.present => const Color(0xFF4CAF50),
    AttendanceCountAs.absent => const Color(0xFFF44336),
    AttendanceCountAs.late => const Color(0xFFFFA726),
    AttendanceCountAs.other => const Color(0xFFBDBDBD),
  };
}

String attendancePercentLabel(double percent) {
  if (percent == 100) return '100%';
  return '${percent.toStringAsFixed(1)}%';
}

AttendanceStats calculateStats(
  List<Attendance> attendances,
  List<AttendanceType> types,
) {
  final typeMap = {for (final t in types) t.id: t};
  var present = 0;
  var absent = 0;
  final typeCounts = <String, int>{};

  for (final a in attendances) {
    final type = typeMap[a.typesId];
    if (type == null) continue;

    typeCounts[type.name] = (typeCounts[type.name] ?? 0) + 1;

    switch (type.countAs) {
      case AttendanceCountAs.present:
      case AttendanceCountAs.other:
        present++;
      case AttendanceCountAs.absent:
      case AttendanceCountAs.late:
        absent++;
    }
  }

  return AttendanceStats(
    totalLessons: present + absent,
    presentCount: present,
    absentCount: absent,
    typeCounts: typeCounts,
  );
}

Map<DateTime, AttendanceDay> groupByDay(
  List<Attendance> attendances,
  List<AttendanceType> types,
  List<ResolvedEvent> resolvedEvents,
) {
  final typeMap = {for (final t in types) t.id: t};
  final eventMap = {for (final e in resolvedEvents) e.id: e};
  final days = <DateTime, List<AttendanceEntry>>{};

  final emittedReplacements = <int>{};

  for (final a in attendances) {
    final type = typeMap[a.typesId];
    if (type == null) continue;

    final re = eventMap[a.eventsId];
    if (re != null && re.isCancelled && !re.isReplaced) continue;

    if (re != null && re.isReplaced) {
      final replacementId = re.replacedByEventId;
      final replacement = replacementId != null
          ? eventMap[replacementId]
          : null;
      if (replacement != null) {
        if (emittedReplacements.contains(replacement.id)) continue;
        emittedReplacements.add(replacement.id);

        final date = replacement.date;
        final dayKey = DateTime(date.year, date.month, date.day);
        final subjectName = replacement.subjectName != null
            ? translateSubjectName(replacement.subjectName!)
            : null;

        days
            .putIfAbsent(dayKey, () => [])
            .add(
              AttendanceEntry(
                attendance: a,
                type: type,
                resolvedEvent: replacement,
                subjectName: subjectName,
                displayLessonNumber: _formatLessonNumbers(
                  replacement.replacedLessonNumbers,
                ),
              ),
            );
      }
      continue;
    }

    if (re != null && re.replacedLessonNumbers.isNotEmpty) {
      if (emittedReplacements.contains(re.id)) continue;
      emittedReplacements.add(re.id);
    }

    final date = re?.date ?? DateTime(2000);
    final dayKey = DateTime(date.year, date.month, date.day);

    final subjectName = re?.subjectName != null
        ? translateSubjectName(re!.subjectName!)
        : null;
    final displayNumber = re != null
        ? (re.replacedLessonNumbers.isNotEmpty
              ? _formatLessonNumbers(re.replacedLessonNumbers)
              : null)
        : null;

    days
        .putIfAbsent(dayKey, () => [])
        .add(
          AttendanceEntry(
            attendance: a,
            type: type,
            resolvedEvent: re,
            subjectName: subjectName,
            displayLessonNumber: displayNumber,
          ),
        );
  }

  return {
    for (final entry in days.entries)
      entry.key: AttendanceDay(date: entry.key, entries: entry.value),
  };
}

String? _formatLessonNumbers(List<int> numbers) {
  final sorted = [...numbers]..sort();
  if (sorted.isEmpty) return null;
  final isContiguous =
      sorted.length > 1 && sorted.last - sorted.first == sorted.length - 1;
  return isContiguous ? '${sorted.first}-${sorted.last}' : sorted.join(', ');
}

List<DateTime> calendarDays(int year, int month) {
  final first = DateTime(year, month);
  final daysInMonth = DateTime(year, month + 1, 0).day;
  final startWeekday = first.weekday;

  final days = <DateTime>[];

  for (var i = 1; i < startWeekday; i++) {
    days.add(first.subtract(Duration(days: startWeekday - i)));
  }

  for (var i = 0; i < daysInMonth; i++) {
    days.add(DateTime(year, month, i + 1));
  }

  while (days.length % 7 != 0) {
    days.add(days.last.add(const Duration(days: 1)));
  }

  return days;
}
