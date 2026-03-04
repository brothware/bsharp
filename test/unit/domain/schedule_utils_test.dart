import 'package:bsharp/domain/entities/event.dart';
import 'package:bsharp/domain/schedule_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Event event({
    int id = 1,
    int number = 1,
    String startTime = '08:00:00',
    String endTime = '08:45:00',
    int status = 1,
    int substitution = 0,
    int locked = 0,
  }) {
    return Event(
      id: id,
      date: DateTime(2026, 2, 27),
      number: number,
      startTime: startTime,
      endTime: endTime,
      eventTypesId: 1,
      status: status,
      substitution: substitution,
      type: 0,
      attr: 0,
      locked: locked,
    );
  }

  group('ScheduleEntry', () {
    test('isCancelled when status is 2', () {
      final entry = ScheduleEntry(event: event(status: 2));
      expect(entry.isCancelled, isTrue);
    });

    test('is not cancelled when status is 0 (scheduled)', () {
      final entry = ScheduleEntry(event: event(status: 0));
      expect(entry.isCancelled, isFalse);
    });

    test('is not cancelled when status is 1 (completed)', () {
      final entry = ScheduleEntry(event: event());
      expect(entry.isCancelled, isFalse);
    });

    test('isSubstitution when substitution is non-zero', () {
      final entry = ScheduleEntry(event: event(substitution: 1));
      expect(entry.isSubstitution, isTrue);
    });

    test('is not substitution when substitution is 0', () {
      final entry = ScheduleEntry(event: event());
      expect(entry.isSubstitution, isFalse);
    });

    test('isLocked when locked is non-zero', () {
      final entry = ScheduleEntry(event: event(locked: 1));
      expect(entry.isLocked, isTrue);
    });

    test('timeRange formats correctly', () {
      final entry = ScheduleEntry(event: event());
      expect(entry.timeRange, '08:00 - 08:45');
    });

    test('timeRange handles short format', () {
      final entry = ScheduleEntry(
        event: event(startTime: '8:00', endTime: '8:45'),
      );
      expect(entry.timeRange, '8:00 - 8:45');
    });
  });

  group('startOfWeek', () {
    test('returns Monday for a Wednesday', () {
      final wed = DateTime(2026, 2, 25);
      final monday = startOfWeek(wed);
      expect(monday, DateTime(2026, 2, 23));
      expect(monday.weekday, DateTime.monday);
    });

    test('returns same day for Monday', () {
      final mon = DateTime(2026, 2, 23);
      expect(startOfWeek(mon), DateTime(2026, 2, 23));
    });

    test('returns Monday for a Friday', () {
      final fri = DateTime(2026, 2, 27);
      final monday = startOfWeek(fri);
      expect(monday, DateTime(2026, 2, 23));
    });

    test('returns Monday for a Sunday', () {
      final sun = DateTime(2026, 3);
      final monday = startOfWeek(sun);
      expect(monday, DateTime(2026, 2, 23));
    });
  });

  group('endOfWeek', () {
    test('returns Friday', () {
      final wed = DateTime(2026, 2, 25);
      final friday = endOfWeek(wed);
      expect(friday, DateTime(2026, 2, 27));
      expect(friday.weekday, DateTime.friday);
    });
  });

  group('weekDays', () {
    test('returns 5 days Mon-Fri', () {
      final days = weekDays(DateTime(2026, 2, 25));
      expect(days.length, 5);
      expect(days.first.weekday, DateTime.monday);
      expect(days.last.weekday, DateTime.friday);
    });
  });

  group('formatDateShort', () {
    test('formats with leading zeros', () {
      expect(formatDateShort(DateTime(2026, 1, 5)), '05.01');
    });

    test('formats double-digit date', () {
      expect(formatDateShort(DateTime(2026, 12, 25)), '25.12');
    });
  });

  group('formatDateFull', () {
    test('includes year', () {
      expect(formatDateFull(DateTime(2026, 2, 27)), '27.02.2026');
    });
  });

  group('dayLabel', () {
    test('returns English abbreviations', () {
      expect(dayLabel(1), 'Mon');
      expect(dayLabel(2), 'Tue');
      expect(dayLabel(3), 'Wed');
      expect(dayLabel(4), 'Thu');
      expect(dayLabel(5), 'Fri');
      expect(dayLabel(6), 'Sat');
      expect(dayLabel(7), 'Sun');
    });

    test('returns empty for invalid weekday', () {
      expect(dayLabel(0), '');
      expect(dayLabel(8), '');
    });
  });

  group('dayLabelFull', () {
    test('returns full English names', () {
      expect(dayLabelFull(1), 'Monday');
      expect(dayLabelFull(5), 'Friday');
      expect(dayLabelFull(7), 'Sunday');
    });
  });

  group('subjectColor', () {
    test('returns consistent color for same id', () {
      expect(subjectColor(5), subjectColor(5));
    });

    test('wraps around palette', () {
      expect(subjectColor(0), subjectColor(12));
    });

    test('handles negative ids', () {
      final color = subjectColor(-3);
      expect(color, isNotNull);
    });
  });

  group('isSameDay', () {
    test('returns true for same date', () {
      expect(
        isSameDay(DateTime(2026, 2, 27), DateTime(2026, 2, 27, 15, 30)),
        isTrue,
      );
    });

    test('returns false for different dates', () {
      expect(isSameDay(DateTime(2026, 2, 27), DateTime(2026, 2, 28)), isFalse);
    });
  });
}
