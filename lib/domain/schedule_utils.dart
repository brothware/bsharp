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
  });

  final Event event;
  final String? subjectName;
  final String? teacherName;
  final String? roomName;
  final String? topic;
  final ScheduleChangeType? changeType;
  final String? originalSubjectName;
  final String? originalTeacherName;

  bool get isCancelled => event.status == 2;
  bool get isSubstitution => event.substitution != 0;
  bool get isLocked => event.locked != 0;

  String get timeRange => '${_formatTime(event.startTime)} - '
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

List<DateTime> weekDays(DateTime date) {
  final monday = startOfWeek(date);
  return List.generate(5, (i) => monday.add(Duration(days: i)));
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

bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
