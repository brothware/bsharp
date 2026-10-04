import 'package:bsharp/domain/entities/attendance.dart';
import 'package:bsharp/domain/entities/portal.dart';
import 'package:bsharp/domain/entities/student.dart';
import 'package:bsharp/domain/entities/subject.dart';
import 'package:bsharp/domain/entities/sync_action.dart';
import 'package:bsharp/domain/entities/teacher.dart';
import 'package:bsharp/domain/entities/term.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Core entities', () {
    test('Student construction and equality', () {
      const student = Student(
        id: 1,
        usersEduId: 100,
        name: 'John',
        surname: 'Smith',
        sex: Sex.male,
      );
      expect(student.id, 1);
      expect(student.name, 'John');
      expect(student.sex, Sex.male);

      const same = Student(
        id: 1,
        usersEduId: 100,
        name: 'John',
        surname: 'Smith',
        sex: Sex.male,
      );
      expect(student, same);
    });

    test('Student copyWith', () {
      const student = Student(
        id: 1,
        usersEduId: 100,
        name: 'John',
        surname: 'Smith',
        sex: Sex.male,
      );
      final modified = student.copyWith(name: 'Adam');
      expect(modified.name, 'Adam');
      expect(modified.id, 1);
    });

    test('Teacher construction', () {
      const teacher = Teacher(
        id: 1,
        login: 'teacher1',
        usersEduId: 200,
        name: 'Anna',
        surname: 'Brown',
        userType: 1,
      );
      expect(teacher.name, 'Anna');
    });

    test('Subject construction', () {
      const subject = Subject(
        id: 1,
        subjectsEduId: 300,
        name: 'Mathematics',
        abbr: 'MATH',
      );
      expect(subject.abbr, 'MATH');
    });

    test('Term construction', () {
      final term = Term(
        id: 1,
        name: 'School year 2025/2026',
        type: TermType.year,
        startDate: DateTime(2025, 9),
        endDate: DateTime(2026, 6, 30),
      );
      expect(term.type, TermType.year);
    });
  });

  group('Attendance entities', () {
    test('Attendance construction', () {
      const attendance = Attendance(
        id: 1,
        eventsId: 10,
        studentsId: 1,
        typesId: 1,
      );
      expect(attendance.typesId, 1);
    });

    test('AttendanceType construction', () {
      const type = AttendanceType(
        id: 1,
        name: 'Present',
        abbr: 'P',
        countAs: AttendanceCountAs.present,
        excuseStatus: AttendanceExcuseStatus.auto,
      );
      expect(type.countAs, AttendanceCountAs.present);
    });
  });

  group('Portal entities', () {
    test('PortalUser construction', () {
      const user = PortalUser(
        login: 'parent1',
        name: 'John',
        surname: 'Smith',
        pupils: [],
      );
      expect(user.pupils, isEmpty);
    });

    test('PortalMark construction', () {
      const mark = PortalMark(
        id: 1,
        subjectId: 100,
        kindLabel: 'Test',
        value: '4+',
        markGroupId: 10,
        parentMarkGroupId: 0,
        date: '2026-02-27',
        weight: 3,
      );
      expect(mark.value, '4+');
    });

    test('PortalAttendanceSummary construction', () {
      const summary = PortalAttendanceSummary(
        percent: 95.5,
        types: [
          PortalAttendanceTypeCount(label: 'Present', count: 100),
          PortalAttendanceTypeCount(label: 'Absent', count: 5),
        ],
      );
      expect(summary.percent, 95.5);
      expect(summary.types, hasLength(2));
    });
  });

  group('Sync enums', () {
    test('SyncAction fromString', () {
      expect(SyncAction.fromString('I'), SyncAction.insert);
      expect(SyncAction.fromString('U'), SyncAction.update);
      expect(SyncAction.fromString('D'), SyncAction.delete);
    });

    test('SyncAction toJsonValue', () {
      expect(SyncAction.insert.toJsonValue(), 'I');
      expect(SyncAction.update.toJsonValue(), 'U');
      expect(SyncAction.delete.toJsonValue(), 'D');
    });

    test('SyncAction fromString throws on unknown', () {
      expect(() => SyncAction.fromString('X'), throwsArgumentError);
    });

    test('Sex fromString', () {
      expect(Sex.fromString('K'), Sex.female);
      expect(Sex.fromString('M'), Sex.male);
    });

    test('Sex toJsonValue', () {
      expect(Sex.female.toJsonValue(), 'K');
      expect(Sex.male.toJsonValue(), 'M');
    });

    test('AttendanceCountAs fromString', () {
      expect(AttendanceCountAs.fromString('P'), AttendanceCountAs.present);
      expect(AttendanceCountAs.fromString('A'), AttendanceCountAs.absent);
    });

    test('TermType fromString', () {
      expect(TermType.fromString('Y'), TermType.year);
      expect(TermType.fromString('S'), TermType.semester);
    });
  });
}
