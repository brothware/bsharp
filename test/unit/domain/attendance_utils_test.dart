import 'package:flutter_test/flutter_test.dart';
import 'package:bsharp/domain/attendance_utils.dart';
import 'package:bsharp/domain/entities/attendance.dart';
import 'package:bsharp/domain/entities/event.dart';
import 'package:bsharp/domain/entities/sync_action.dart';

void main() {
  const presentType = AttendanceType(
    id: 1,
    name: 'Present',
    abbr: 'PR',
    countAs: AttendanceCountAs.present,
    excuseStatus: AttendanceExcuseStatus.auto,
  );

  const absentType = AttendanceType(
    id: 2,
    name: 'Absent',
    abbr: 'AB',
    countAs: AttendanceCountAs.absent,
    excuseStatus: AttendanceExcuseStatus.unexcused,
  );

  const lateType = AttendanceType(
    id: 3,
    name: 'Late',
    abbr: 'LT',
    countAs: AttendanceCountAs.late,
    excuseStatus: AttendanceExcuseStatus.unset,
  );

  Attendance _attendance({int id = 1, int eventsId = 1, int typesId = 1}) {
    return Attendance(
      id: id,
      eventsId: eventsId,
      studentsId: 1,
      typesId: typesId,
    );
  }

  Event _event({int id = 1, DateTime? date, int number = 1}) {
    return Event(
      id: id,
      date: date ?? DateTime(2026, 2, 27),
      number: number,
      startTime: '08:00:00',
      endTime: '08:45:00',
      eventTypesId: 1,
      status: 1,
      substitution: 0,
      type: 0,
      attr: 0,
      locked: 0,
    );
  }

  group('AttendanceDay', () {
    test('presentCount counts present types', () {
      final day = AttendanceDay(
        date: DateTime(2026, 2, 27),
        entries: [
          AttendanceEntry(
            attendance: _attendance(typesId: 1),
            type: presentType,
          ),
          AttendanceEntry(
            attendance: _attendance(typesId: 2),
            type: absentType,
          ),
          AttendanceEntry(attendance: _attendance(typesId: 3), type: lateType),
        ],
      );

      expect(day.presentCount, 1);
      expect(day.absentCount, 2);
    });

    test('status is present when all present', () {
      final day = AttendanceDay(
        date: DateTime(2026, 2, 27),
        entries: [
          AttendanceEntry(attendance: _attendance(), type: presentType),
        ],
      );
      expect(day.status, AttendanceDayStatus.present);
    });

    test('status is unexcused when all absent and unexcused', () {
      final day = AttendanceDay(
        date: DateTime(2026, 2, 27),
        entries: [
          AttendanceEntry(
            attendance: _attendance(typesId: 2),
            type: absentType,
          ),
        ],
      );
      expect(day.status, AttendanceDayStatus.unexcused);
    });

    test('status is excused when all absent and excused', () {
      const excusedType = AttendanceType(
        id: 4,
        name: 'Excused absence',
        abbr: 'EA',
        countAs: AttendanceCountAs.absent,
        excuseStatus: AttendanceExcuseStatus.excused,
      );
      final day = AttendanceDay(
        date: DateTime(2026, 2, 27),
        entries: [
          AttendanceEntry(
            attendance: _attendance(typesId: 4),
            type: excusedType,
          ),
        ],
      );
      expect(day.status, AttendanceDayStatus.excused);
    });

    test('status is late when only late entries', () {
      final day = AttendanceDay(
        date: DateTime(2026, 2, 27),
        entries: [
          AttendanceEntry(attendance: _attendance(typesId: 3), type: lateType),
        ],
      );
      expect(day.status, AttendanceDayStatus.late);
    });

    test('status is mixed when both present and absent', () {
      const excusedType = AttendanceType(
        id: 4,
        name: 'Excused absence',
        abbr: 'EA',
        countAs: AttendanceCountAs.absent,
        excuseStatus: AttendanceExcuseStatus.excused,
      );
      final day = AttendanceDay(
        date: DateTime(2026, 2, 27),
        entries: [
          AttendanceEntry(
            attendance: _attendance(typesId: 1),
            type: presentType,
          ),
          AttendanceEntry(
            attendance: _attendance(typesId: 4),
            type: excusedType,
          ),
        ],
      );
      expect(day.status, AttendanceDayStatus.mixed);
    });

    test('status is noData when empty', () {
      final day = AttendanceDay(date: DateTime(2026, 2, 27), entries: []);
      expect(day.status, AttendanceDayStatus.noData);
    });
  });

  group('attendanceStatusColor', () {
    test('returns different colors for each status', () {
      final colors = AttendanceDayStatus.values
          .map(attendanceStatusColor)
          .toSet();
      expect(colors.length, 5);
    });
  });

  group('attendancePercentLabel', () {
    test('formats 100 without decimal', () {
      expect(attendancePercentLabel(100), '100%');
    });

    test('formats with one decimal', () {
      expect(attendancePercentLabel(87.5), '87.5%');
    });

    test('formats zero', () {
      expect(attendancePercentLabel(0), '0.0%');
    });
  });

  group('calculateStats', () {
    test('counts present and absent correctly', () {
      final stats = calculateStats(
        [
          _attendance(id: 1, typesId: 1),
          _attendance(id: 2, typesId: 1),
          _attendance(id: 3, typesId: 2),
        ],
        [presentType, absentType],
      );

      expect(stats.totalLessons, 3);
      expect(stats.presentCount, 2);
      expect(stats.absentCount, 1);
      expect(stats.presentPercent, closeTo(66.7, 0.1));
    });

    test('returns zero percent when no data', () {
      final stats = calculateStats([], [presentType]);
      expect(stats.presentPercent, 0);
      expect(stats.absentPercent, 0);
    });

    test('builds type counts map', () {
      final stats = calculateStats(
        [
          _attendance(id: 1, typesId: 1),
          _attendance(id: 2, typesId: 3),
          _attendance(id: 3, typesId: 3),
        ],
        [presentType, lateType],
      );

      expect(stats.typeCounts['Present'], 1);
      expect(stats.typeCounts['Late'], 2);
    });

    test('skips attendances with unknown type', () {
      final stats = calculateStats(
        [_attendance(id: 1, typesId: 999)],
        [presentType],
      );
      expect(stats.totalLessons, 0);
    });
  });

  group('groupByDay', () {
    test('groups attendances by event date', () {
      final events = [
        _event(id: 1, date: DateTime(2026, 2, 27), number: 1),
        _event(id: 2, date: DateTime(2026, 2, 27), number: 2),
        _event(id: 3, date: DateTime(2026, 2, 28), number: 1),
      ];

      final result = groupByDay(
        [
          _attendance(id: 1, eventsId: 1, typesId: 1),
          _attendance(id: 2, eventsId: 2, typesId: 1),
          _attendance(id: 3, eventsId: 3, typesId: 2),
        ],
        [presentType, absentType],
        events,
      );

      expect(result.length, 2);
      expect(result[DateTime(2026, 2, 27)]!.entries.length, 2);
      expect(result[DateTime(2026, 2, 28)]!.entries.length, 1);
    });

    test('skips attendances with unknown type', () {
      final result = groupByDay(
        [_attendance(id: 1, eventsId: 1, typesId: 999)],
        [presentType],
        [_event(id: 1)],
      );
      expect(result, isEmpty);
    });
  });

  group('calendarDays', () {
    test('returns days covering full weeks', () {
      final days = calendarDays(2026, 2);
      expect(days.length % 7, 0);
    });

    test('starts on Monday', () {
      final days = calendarDays(2026, 2);
      expect(days.first.weekday, DateTime.monday);
    });

    test('ends on Sunday', () {
      final days = calendarDays(2026, 2);
      expect(days.last.weekday, DateTime.sunday);
    });

    test('contains all days of month', () {
      final days = calendarDays(2026, 2);
      final februaryDays = days.where((d) => d.month == 2 && d.year == 2026);
      expect(februaryDays.length, 28);
    });

    test('handles months starting on Monday', () {
      final days = calendarDays(2026, 6);
      expect(days.first, DateTime(2026, 6, 1));
    });
  });
}
