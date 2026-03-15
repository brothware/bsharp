import 'package:bsharp/domain/attendance_utils.dart';
import 'package:bsharp/domain/entities/attendance.dart';
import 'package:bsharp/domain/entities/resolved_event.dart';
import 'package:bsharp/domain/entities/sync_action.dart';
import 'package:flutter_test/flutter_test.dart';

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

  Attendance attendance({int id = 1, int eventsId = 1, int typesId = 1}) {
    return Attendance(
      id: id,
      eventsId: eventsId,
      studentsId: 1,
      typesId: typesId,
    );
  }

  ResolvedEvent resolvedEvent({
    int id = 1,
    DateTime? date,
    int number = 1,
    String? subjectName,
    bool isCancelled = false,
    bool isSubstitution = false,
    bool isReplaced = false,
    int? replacedByEventId,
    List<int> replacedLessonNumbers = const [],
  }) {
    return ResolvedEvent(
      id: id,
      date: date ?? DateTime(2026, 2, 27),
      number: number,
      startTime: '08:00:00',
      endTime: '08:45:00',
      subjectName: subjectName,
      isCancelled: isCancelled,
      isSubstitution: isSubstitution,
      isReplaced: isReplaced,
      replacedByEventId: replacedByEventId,
      replacedLessonNumbers: replacedLessonNumbers,
    );
  }

  group('AttendanceDay', () {
    test('presentCount counts present types', () {
      final day = AttendanceDay(
        date: DateTime(2026, 2, 27),
        entries: [
          AttendanceEntry(attendance: attendance(), type: presentType),
          AttendanceEntry(attendance: attendance(typesId: 2), type: absentType),
          AttendanceEntry(attendance: attendance(typesId: 3), type: lateType),
        ],
      );

      expect(day.presentCount, 1);
      expect(day.absentCount, 2);
    });

    test('status is present when all present', () {
      final day = AttendanceDay(
        date: DateTime(2026, 2, 27),
        entries: [AttendanceEntry(attendance: attendance(), type: presentType)],
      );
      expect(day.status, AttendanceDayStatus.present);
    });

    test('status is unexcused when all absent and unexcused', () {
      final day = AttendanceDay(
        date: DateTime(2026, 2, 27),
        entries: [
          AttendanceEntry(attendance: attendance(typesId: 2), type: absentType),
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
            attendance: attendance(typesId: 4),
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
          AttendanceEntry(attendance: attendance(typesId: 3), type: lateType),
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
          AttendanceEntry(attendance: attendance(), type: presentType),
          AttendanceEntry(
            attendance: attendance(typesId: 4),
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
        [attendance(), attendance(id: 2), attendance(id: 3, typesId: 2)],
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
          attendance(),
          attendance(id: 2, typesId: 3),
          attendance(id: 3, typesId: 3),
        ],
        [presentType, lateType],
      );

      expect(stats.typeCounts['Present'], 1);
      expect(stats.typeCounts['Late'], 2);
    });

    test('skips attendances with unknown type', () {
      final stats = calculateStats([attendance(typesId: 999)], [presentType]);
      expect(stats.totalLessons, 0);
    });
  });

  group('groupByDay', () {
    test('groups attendances by event date', () {
      final events = [
        resolvedEvent(date: DateTime(2026, 2, 27)),
        resolvedEvent(id: 2, date: DateTime(2026, 2, 27), number: 2),
        resolvedEvent(id: 3, date: DateTime(2026, 2, 28)),
      ];

      final result = groupByDay(
        [
          attendance(),
          attendance(id: 2, eventsId: 2),
          attendance(id: 3, eventsId: 3, typesId: 2),
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
        [attendance(typesId: 999)],
        [presentType],
        [resolvedEvent()],
      );
      expect(result, isEmpty);
    });

    test('resolves subject name from resolved event', () {
      final result = groupByDay(
        [attendance()],
        [presentType],
        [resolvedEvent(subjectName: 'Mathematics')],
      );

      final entries = result[DateTime(2026, 2, 27)]!.entries;
      expect(entries.first.subjectName, isNotNull);
    });

    test('leaves subjectName null when resolved event has no subject', () {
      final result = groupByDay(
        [attendance()],
        [presentType],
        [resolvedEvent()],
      );

      final entries = result[DateTime(2026, 2, 27)]!.entries;
      expect(entries.first.subjectName, isNull);
    });

    test('collapses replaced events into single replacement entry', () {
      final result = groupByDay(
        [
          attendance(eventsId: 10),
          attendance(id: 2, eventsId: 11),
          attendance(id: 3, eventsId: 12),
        ],
        [presentType],
        [
          resolvedEvent(
            id: 10,
            isCancelled: true,
            isReplaced: true,
            replacedByEventId: 20,
          ),
          resolvedEvent(
            id: 11,
            number: 2,
            isCancelled: true,
            isReplaced: true,
            replacedByEventId: 20,
          ),
          resolvedEvent(
            id: 12,
            number: 3,
            isCancelled: true,
            isReplaced: true,
            replacedByEventId: 20,
          ),
          resolvedEvent(
            id: 20,
            number: 0,
            subjectName: 'PE',
            isSubstitution: true,
            replacedLessonNumbers: [1, 2, 3],
          ),
        ],
      );

      final entries = result[DateTime(2026, 2, 27)]!.entries;
      expect(entries.length, 1);
      expect(entries.first.resolvedEvent!.id, 20);
      expect(entries.first.subjectName, contains('PE'));
    });

    test('excludes attendance for standalone cancelled events', () {
      final result = groupByDay(
        [
          attendance(),
          attendance(id: 2, eventsId: 2),
          attendance(id: 3, eventsId: 3),
        ],
        [presentType],
        [
          resolvedEvent(isCancelled: true),
          resolvedEvent(id: 2),
          resolvedEvent(id: 3, isCancelled: true),
        ],
      );

      final entries = result[DateTime(2026, 2, 27)]!.entries;
      expect(entries.length, 1);
      expect(entries.first.attendance.eventsId, 2);
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
      expect(days.first, DateTime(2026, 6));
    });
  });
}
