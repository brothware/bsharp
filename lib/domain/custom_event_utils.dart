import 'package:bsharp/domain/entities/custom_event.dart';

bool weekdayBitmaskHas(int bitmask, int weekday) =>
    bitmask & (1 << (weekday - 1)) != 0;

int weekdayBitmaskSet(int bitmask, int weekday, {required bool enabled}) {
  if (enabled) return bitmask | (1 << (weekday - 1));
  return bitmask & ~(1 << (weekday - 1));
}

List<DateTime> generateOccurrences(CustomEvent event) {
  if (event.recurrenceType != RecurrenceType.weekly) return [];
  final start = event.recurrenceStartDate;
  final end = event.recurrenceEndDate;
  final weekdays = event.recurrenceWeekdays;
  if (start == null || end == null || weekdays == null || weekdays == 0) {
    return [];
  }

  final dates = <DateTime>[];
  var current = DateTime(start.year, start.month, start.day);
  final limit = DateTime(end.year, end.month, end.day);

  while (!current.isAfter(limit)) {
    if (weekdayBitmaskHas(weekdays, current.weekday)) {
      dates.add(current);
    }
    current = current.add(const Duration(days: 1));
  }

  return dates;
}
