import 'package:bsharp/domain/schedule_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ScheduleEntry entry({
    int id = 1,
    int number = 1,
    String startTime = '08:00:00',
    String endTime = '08:45:00',
    bool isCancelled = false,
    bool isSubstitution = false,
    bool isLocked = false,
    bool isReplaced = false,
    List<int> replacedLessonNumbers = const [],
  }) {
    return ScheduleEntry(
      id: id,
      date: DateTime(2026, 2, 27),
      number: number,
      startTime: startTime,
      endTime: endTime,
      isCancelled: isCancelled,
      isSubstitution: isSubstitution,
      isLocked: isLocked,
      isReplaced: isReplaced,
      replacedLessonNumbers: replacedLessonNumbers,
    );
  }

  group('ScheduleEntry', () {
    test('isCancelled when set to true', () {
      final e = entry(isCancelled: true);
      expect(e.isCancelled, isTrue);
    });

    test('is not cancelled by default', () {
      final e = entry();
      expect(e.isCancelled, isFalse);
    });

    test('is not cancelled by default', () {
      final e = entry();
      expect(e.isCancelled, isFalse);
    });

    test('isSubstitution when set to true', () {
      final e = entry(isSubstitution: true);
      expect(e.isSubstitution, isTrue);
    });

    test('is not substitution by default', () {
      final e = entry();
      expect(e.isSubstitution, isFalse);
    });

    test('isLocked when set to true', () {
      final e = entry(isLocked: true);
      expect(e.isLocked, isTrue);
    });

    test('timeRange formats correctly', () {
      final e = entry();
      expect(e.timeRange, '08:00 - 08:45');
    });

    test('timeRange handles short format', () {
      final e = entry(startTime: '8:00', endTime: '8:45');
      expect(e.timeRange, '8:00 - 8:45');
    });

    test('displayLessonNumber shows event number by default', () {
      final e = entry(number: 3);
      expect(e.displayLessonNumber, '3');
    });

    test('displayLessonNumber shows dash for replaced entries', () {
      final e = entry(isReplaced: true);
      expect(e.displayLessonNumber, '-');
    });

    test('displayLessonNumber shows contiguous range', () {
      final e = entry(replacedLessonNumbers: [5, 6, 7]);
      expect(e.displayLessonNumber, '5-7');
    });

    test('displayLessonNumber shows comma-separated for non-contiguous', () {
      final e = entry(replacedLessonNumbers: [2, 5, 7]);
      expect(e.displayLessonNumber, '2, 5, 7');
    });

    test('displayLessonNumber shows single number in list', () {
      final e = entry(replacedLessonNumbers: [4]);
      expect(e.displayLessonNumber, '4');
    });

    test('isReplaced defaults to false', () {
      final e = entry();
      expect(e.isReplaced, isFalse);
    });

    test('replacedLessonNumbers defaults to empty', () {
      final e = entry();
      expect(e.replacedLessonNumbers, isEmpty);
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
    test('returns consistent color for same name', () {
      expect(subjectColor('Mathematics'), subjectColor('Mathematics'));
    });

    test('returns different colors for different names', () {
      expect(subjectColor('Mathematics'), isNot(subjectColor('Physics')));
    });

    test('handles empty string', () {
      final color = subjectColor('');
      expect(color, isNotNull);
    });
  });

  group('nextScheduleDay', () {
    test('Monday to Tuesday', () {
      final mon = DateTime(2026, 3, 9);
      expect(
        nextScheduleDay(mon, includeWeekends: false),
        DateTime(2026, 3, 10),
      );
    });

    test('Friday to Monday when weekends excluded', () {
      final fri = DateTime(2026, 3, 13);
      expect(
        nextScheduleDay(fri, includeWeekends: false),
        DateTime(2026, 3, 16),
      );
    });

    test('Friday to Saturday when weekends included', () {
      final fri = DateTime(2026, 3, 13);
      expect(
        nextScheduleDay(fri, includeWeekends: true),
        DateTime(2026, 3, 14),
      );
    });

    test('Saturday to Monday when weekends excluded', () {
      final sat = DateTime(2026, 3, 14);
      expect(
        nextScheduleDay(sat, includeWeekends: false),
        DateTime(2026, 3, 16),
      );
    });

    test('Sunday to Monday when weekends excluded', () {
      final sun = DateTime(2026, 3, 15);
      expect(
        nextScheduleDay(sun, includeWeekends: false),
        DateTime(2026, 3, 16),
      );
    });

    test('crosses month boundary', () {
      final fri = DateTime(2026, 1, 30);
      expect(
        nextScheduleDay(fri, includeWeekends: false),
        DateTime(2026, 2, 2),
      );
    });
  });

  group('previousScheduleDay', () {
    test('Tuesday to Monday', () {
      final tue = DateTime(2026, 3, 10);
      expect(
        previousScheduleDay(tue, includeWeekends: false),
        DateTime(2026, 3, 9),
      );
    });

    test('Monday to Friday when weekends excluded', () {
      final mon = DateTime(2026, 3, 16);
      expect(
        previousScheduleDay(mon, includeWeekends: false),
        DateTime(2026, 3, 13),
      );
    });

    test('Monday to Sunday when weekends included', () {
      final mon = DateTime(2026, 3, 16);
      expect(
        previousScheduleDay(mon, includeWeekends: true),
        DateTime(2026, 3, 15),
      );
    });

    test('Sunday to Friday when weekends excluded', () {
      final sun = DateTime(2026, 3, 15);
      expect(
        previousScheduleDay(sun, includeWeekends: false),
        DateTime(2026, 3, 13),
      );
    });

    test('Saturday to Friday when weekends excluded', () {
      final sat = DateTime(2026, 3, 14);
      expect(
        previousScheduleDay(sat, includeWeekends: false),
        DateTime(2026, 3, 13),
      );
    });

    test('crosses month boundary', () {
      final mon = DateTime(2026, 2, 2);
      expect(
        previousScheduleDay(mon, includeWeekends: false),
        DateTime(2026, 1, 30),
      );
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
