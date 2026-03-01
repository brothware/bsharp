import 'dart:ui';

import 'package:bsharp/domain/entities/event.dart';

class ScheduleEntry {
  ScheduleEntry({
    required this.event,
    this.subjectName,
    this.teacherName,
    this.roomName,
    this.topic,
    this.changeType,
  });

  final Event event;
  final String? subjectName;
  final String? teacherName;
  final String? roomName;
  final String? topic;
  final ScheduleChangeType? changeType;

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

String dayLabel(int weekday, {List<String>? labels}) {
  if (labels != null && weekday >= 1 && weekday <= labels.length) {
    return labels[weekday - 1];
  }
  return switch (weekday) {
    1 => 'Mon',
    2 => 'Tue',
    3 => 'Wed',
    4 => 'Thu',
    5 => 'Fri',
    6 => 'Sat',
    7 => 'Sun',
    _ => '',
  };
}

String dayLabelFull(int weekday, {List<String>? labels}) {
  if (labels != null && weekday >= 1 && weekday <= labels.length) {
    return labels[weekday - 1];
  }
  return switch (weekday) {
    1 => 'Monday',
    2 => 'Tuesday',
    3 => 'Wednesday',
    4 => 'Thursday',
    5 => 'Friday',
    6 => 'Saturday',
    7 => 'Sunday',
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
