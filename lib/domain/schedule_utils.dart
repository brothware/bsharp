import 'dart:ui';

import 'package:bsharp/domain/entities/resolved_event.dart';
import 'package:bsharp/domain/translation_utils.dart';
import 'package:bsharp/l10n/strings.g.dart';

class ScheduleEntry {
  ScheduleEntry({
    required this.id,
    required this.date,
    required this.number,
    required this.startTime,
    required this.endTime,
    this.subjectName,
    this.teacherName,
    this.roomName,
    this.topic,
    this.subjectId,
    this.isCancelled = false,
    this.isSubstitution = false,
    this.isLocked = false,
    this.changeType,
    this.originalSubjectName,
    this.originalTeacherName,
    this.replacedLessonNumbers = const [],
    this.isReplaced = false,
    this.eventName,
  });

  factory ScheduleEntry.fromResolved(ResolvedEvent re) {
    ScheduleChangeType? changeType;
    if (re.isReplaced || re.isCancelled) {
      changeType = ScheduleChangeType.cancelled;
    } else if (re.isSubstitution) {
      changeType = ScheduleChangeType.substitution;
    }
    return ScheduleEntry(
      id: re.id,
      date: re.date,
      number: re.number,
      startTime: re.startTime,
      endTime: re.endTime,
      subjectName: re.subjectName != null
          ? translateSubjectName(re.subjectName!)
          : null,
      teacherName: re.teacherName,
      roomName: re.roomName,
      topic: re.topic,
      subjectId: re.subjectId,
      isCancelled: re.isCancelled,
      isSubstitution: re.isSubstitution,
      isLocked: re.isLocked,
      changeType: changeType,
      originalSubjectName: re.originalSubjectName != null
          ? translateSubjectName(re.originalSubjectName!)
          : null,
      originalTeacherName: re.originalTeacherName,
      replacedLessonNumbers: re.replacedLessonNumbers,
      isReplaced: re.isReplaced,
      eventName: re.eventName,
    );
  }

  final int id;
  final DateTime date;
  final int number;
  final String startTime;
  final String endTime;
  final String? subjectName;
  final String? teacherName;
  final String? roomName;
  final String? topic;
  final int? subjectId;
  final bool isCancelled;
  final bool isSubstitution;
  final bool isLocked;
  final ScheduleChangeType? changeType;
  final String? originalSubjectName;
  final String? originalTeacherName;
  final List<int> replacedLessonNumbers;
  final bool isReplaced;
  final String? eventName;

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
    return '$number';
  }

  String get timeRange =>
      '${_formatTime(startTime)} - '
      '${_formatTime(endTime)}';

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

Color subjectColor(String name) {
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
  var hash = 0;
  for (var i = 0; i < name.length; i++) {
    hash = (hash * 31 + name.codeUnitAt(i)) & 0x7FFFFFFF;
  }
  return palette[hash % palette.length];
}

Color subjectColorByIndex(int index) {
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
  return palette[index.abs() % palette.length];
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
