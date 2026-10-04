import 'package:bsharp/data/providers/mobireg/parsers/attendance_parser.dart';
import 'package:bsharp/data/services/mobireg_translations.dart';
import 'package:bsharp/domain/entities/sync_action.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fixtures/mobireg/fixtures.dart';

void main() {
  group('parseAttendance', () {
    final parsed = parseAttendance(
      timetableEvents: loadMobiregFixture('timetable_events'),
      attendanceStats: loadMobiregFixture('attendance_stats'),
      pupilId: 6339,
    );

    test('records attendance only for checked lessons', () {
      expect(
        parsed.attendances.map((a) => a.eventsId),
        unorderedEquals([173, 150190]),
      );
      expect(parsed.attendances.every((a) => a.id == a.eventsId), isTrue);
      expect(parsed.attendances.every((a) => a.studentsId == 6339), isTrue);
    });

    test('joins each attendance to the type with its label', () {
      final byId = {for (final t in parsed.types) t.id: t};
      final absent = parsed.attendances.firstWhere((a) => a.eventsId == 150190);
      expect(byId[absent.typesId]!.countAs, AttendanceCountAs.absent);
      expect(
        byId[absent.typesId]!.excuseStatus,
        AttendanceExcuseStatus.unexcused,
      );
    });

    test('derives excuse status from the type name', () {
      AttendanceExcuseStatus statusOf(String label) => parsed.types
          .firstWhere((t) => t.name == normalizeMobiregAttendanceName(label))
          .excuseStatus;

      expect(
        statusOf('Nieobecność usprawiedliwiona'),
        AttendanceExcuseStatus.excused,
      );
      expect(statusOf('Nieobecność'), AttendanceExcuseStatus.unexcused);
      expect(statusOf('Próba chóru'), AttendanceExcuseStatus.unset);
      expect(statusOf('Obecność'), AttendanceExcuseStatus.unset);
    });

    test('normalises the abbreviation of each type', () {
      expect(
        parsed.types.map((t) => t.abbr),
        containsAll([
          normalizeMobiregAttendanceAbbr('O'),
          normalizeMobiregAttendanceAbbr('NU'),
          normalizeMobiregAttendanceAbbr('N'),
          normalizeMobiregAttendanceAbbr('ph'),
        ]),
      );
    });

    test('assigns the same type ids on every parse', () {
      final again = parseAttendance(
        timetableEvents: loadMobiregFixture('timetable_events'),
        attendanceStats: loadMobiregFixture('attendance_stats'),
        pupilId: 6339,
      );
      expect(again.types, parsed.types);
    });

    test('a stats payload that is not an object is a FormatException', () {
      expect(
        () => parseAttendance(
          timetableEvents: <Object>[],
          attendanceStats: <Object>[],
          pupilId: 1,
        ),
        throwsFormatException,
      );
    });
  });
}
