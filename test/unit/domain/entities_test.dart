import 'package:bsharp/domain/entities/attendance.dart';
import 'package:bsharp/domain/entities/event.dart';
import 'package:bsharp/domain/entities/group.dart';
import 'package:bsharp/domain/entities/lesson.dart';
import 'package:bsharp/domain/entities/mark.dart';
import 'package:bsharp/domain/entities/message.dart';
import 'package:bsharp/domain/entities/organization.dart';
import 'package:bsharp/domain/entities/permission.dart';
import 'package:bsharp/domain/entities/portal.dart';
import 'package:bsharp/domain/entities/room.dart';
import 'package:bsharp/domain/entities/settings.dart';
import 'package:bsharp/domain/entities/student.dart';
import 'package:bsharp/domain/entities/subject.dart';
import 'package:bsharp/domain/entities/sync_action.dart';
import 'package:bsharp/domain/entities/teacher.dart';
import 'package:bsharp/domain/entities/term.dart';
import 'package:bsharp/domain/entities/user_reprimand.dart';
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

    test('Group construction', () {
      const group = Group(id: 1, groupsEduId: 400, name: 'Class 3a', type: 'C');
      expect(group.type, 'C');
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

    test('Room construction', () {
      const room = Room(id: 1, name: '1.02');
      expect(room.name, '1.02');
    });

    test('ServerSettings construction', () {
      final settings = ServerSettings(
        version: '1.6.0',
        protocol: '1.6.0',
        id: 'abc123',
        time: DateTime(2026, 2, 27),
        permissions: 1,
      );
      expect(settings.protocol, '1.6.0');
    });
  });

  group('Schedule entities', () {
    test('Event construction', () {
      final event = Event(
        id: 1,
        date: DateTime(2026, 2, 27),
        number: 1,
        startTime: '08:00:00',
        endTime: '08:45:00',
        eventTypesId: 10,
        status: 1,
        substitution: 0,
        type: 0,
        attr: 0,
        locked: 0,
      );
      expect(event.number, 1);
      expect(event.status, 1);
    });

    test('EventType construction', () {
      const et = EventType(
        id: 1,
        subjectsId: 5,
        teachingLevel: 1,
        substitution: 0,
      );
      expect(et.subjectsId, 5);
    });

    test('Lesson construction', () {
      const lesson = Lesson(
        id: 1,
        lessonGroupsId: 1,
        lessonNumber: 3,
        startTime: '10:00:00',
        endTime: '10:45:00',
      );
      expect(lesson.lessonNumber, 3);
    });
  });

  group('Grade entities', () {
    test('Mark construction', () {
      final mark = Mark(
        id: 1,
        markGroupsId: 10,
        pupilUsersId: 1,
        teacherUsersId: 5,
        weight: 3,
        getDate: DateTime(2026, 2, 27),
        modified: 0,
        markValue: 4.5,
      );
      expect(mark.markValue, 4.5);
      expect(mark.weight, 3);
    });

    test('MarkScale construction', () {
      const scale = MarkScale(
        id: 1,
        markScaleGroupsId: 1,
        abbreviation: '5',
        name: 'Very good',
        markValue: 5,
        classified: 1,
        noCountToAverage: 0,
      );
      expect(scale.abbreviation, '5');
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

  group('Message entity', () {
    test('Message construction', () {
      final message = Message(
        id: 1,
        sendTime: DateTime(2026, 2, 27),
        senderUsersId: 5,
        recipientUsersId: 1,
        title: 'Test',
        content: 'Hello',
      );
      expect(message.readTime, isNull);
    });
  });

  group('UserReprimand entity', () {
    test('construction', () {
      final reprimand = UserReprimand(
        id: 1,
        studentsId: 1,
        teachersId: 5,
        kind: ReprimandKind.praise,
        getDate: DateTime(2026, 2, 27),
        content: 'Great work!',
        status: 1,
      );
      expect(reprimand.kind, ReprimandKind.praise);
    });
  });

  group('Organization entities', () {
    test('StudentGroup construction', () {
      const sg = StudentGroup(id: 1, studentsId: 1, groupsId: 1, number: 15);
      expect(sg.number, 15);
    });

    test('GroupEducator construction', () {
      const ge = GroupEducator(id: 1, groupsId: 1, teachersEducatorId: 5);
      expect(ge.teachersEducatorId, 5);
    });
  });

  group('Permission entities', () {
    test('PermissionGroup construction', () {
      const pg = PermissionGroup(id: 1, permissionGroupsId: 1, name: 'Admin');
      expect(pg.name, 'Admin');
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

    test('ReprimandKind fromInt', () {
      expect(ReprimandKind.fromInt(0), ReprimandKind.note);
      expect(ReprimandKind.fromInt(1), ReprimandKind.praise);
    });

    test('TermType fromString', () {
      expect(TermType.fromString('Y'), TermType.year);
      expect(TermType.fromString('S'), TermType.semester);
    });
  });
}
