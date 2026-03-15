import 'dart:math';

import 'package:bsharp/app/child_provider.dart';
import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/data/providers/demo/demo_grade_data.dart';
import 'package:bsharp/data/providers/demo/demo_message_data.dart';
import 'package:bsharp/data/providers/demo/demo_portal_data.dart';
import 'package:bsharp/data/providers/demo/demo_schedule_data.dart';
import 'package:bsharp/domain/entities/attendance.dart';
import 'package:bsharp/domain/entities/poczta.dart';
import 'package:bsharp/domain/entities/resolved_event.dart';
import 'package:bsharp/domain/entities/student.dart';
import 'package:bsharp/domain/entities/subject.dart';
import 'package:bsharp/domain/entities/sync_action.dart';
import 'package:bsharp/domain/entities/teacher.dart';
import 'package:bsharp/domain/entities/term.dart';
import 'package:bsharp/domain/school_data_provider.dart';
import 'package:bsharp/presentation/attendance/providers/attendance_providers.dart';
import 'package:bsharp/presentation/grades/providers/grades_providers.dart';
import 'package:bsharp/presentation/messages/providers/messages_providers.dart';
import 'package:bsharp/presentation/more/providers/more_providers.dart';
import 'package:bsharp/presentation/schedule/providers/schedule_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DemoDataProvider implements SchoolDataProvider {
  @override
  String get id => 'demo';

  @override
  String get displayName => 'Demo';

  @override
  Set<DataProviderCapability> get capabilities =>
      DataProviderCapability.values.toSet()
        ..remove(DataProviderCapability.sendMessages);

  @override
  bool get requiresCredentials => false;

  @override
  bool supports(DataProviderCapability cap) => capabilities.contains(cap);

  @override
  Future<void> authenticate({
    required String school,
    required String login,
    required String passwordHash,
  }) async {}

  @override
  Future<void> loadSchoolData(
    Ref ref, {
    required int studentId,
    DateTime? now,
  }) async {
    now ??= DateTime.now();
    final schoolYearStart = now.month >= 9
        ? DateTime(now.year, 9)
        : DateTime(now.year - 1, 9);
    final schoolYearEnd = DateTime(schoolYearStart.year + 1, 6, 30);
    final semesterEnd = DateTime(schoolYearStart.year + 1, 1, 31);

    ref.read(studentsProvider.notifier).value = [
      const Student(
        id: 1,
        usersEduId: 1,
        name: 'Jan',
        surname: 'Kowalski',
        sex: Sex.male,
      ),
    ];

    final teachers = _buildTeachers();
    ref.read(teachersProvider.notifier).value = teachers;

    final subjects = _buildSubjects();
    ref.read(subjectsProvider.notifier).value = subjects;

    final terms = _buildTerms(schoolYearStart, schoolYearEnd, semesterEnd);
    ref.read(termsProvider.notifier).value = terms;

    final resolvedEvents = buildDemoResolvedEvents(now, subjects, teachers);
    ref.read(resolvedEventsProvider.notifier).value = resolvedEvents;

    ref.read(resolvedGradesProvider.notifier).value = buildDemoResolvedGrades(
      subjects,
      teachers,
      now,
    );

    final attendanceTypes = _buildAttendanceTypes();
    ref.read(attendanceTypesProvider.notifier).value = attendanceTypes;
    ref.read(attendancesProvider.notifier).value = _buildAttendances(
      resolvedEvents,
      attendanceTypes,
    );

    ref.read(homeworksProvider.notifier).value = buildDemoHomeworks(now);
    ref.read(testsProvider.notifier).value = buildDemoTests(now);
    ref.read(reprimandsProvider.notifier).value = buildDemoReprimands(
      now,
      teachers,
    );
    ref.read(bulletinsProvider.notifier).value = buildDemoBulletins(now);
    ref.read(gradeChangelogProvider.notifier).value = buildDemoChangelog(now);
    ref.read(attendanceChangelogProvider.notifier).value = [];
  }

  @override
  Future<void> loadMessages(Ref ref, {DateTime? now}) async {
    now ??= DateTime.now();
    ref.read(inboxProvider.notifier).value = buildDemoInbox(now);
    ref.read(sentProvider.notifier).value = buildDemoSent(now);
    ref.read(trashProvider.notifier).value = buildDemoTrash(now);
  }

  @override
  Future<void> refreshMessages(Ref ref) async {}

  @override
  Future<Map<String, dynamic>?> readMessage(int messageId) async => null;

  @override
  Future<List<PocztaReceiver>> searchReceivers(String query) async => [];

  @override
  Future<void> toggleStar(int messageId) async {}

  @override
  Future<void> deleteMessage(int messageId) async {}

  @override
  Future<void> restoreMessage(int messageId) async {}

  @override
  Future<void> sendMessage({
    required List<String> recipientIds,
    required String title,
    required String content,
    int? previousMessageId,
  }) async {}

  @override
  Future<List<PocztaMessage>> loadMoreInbox(int skip) async => [];

  @override
  Future<String?> downloadAttachment(String url, String filename) async => null;

  @override
  String hashPassword(String password) => '';

  @override
  Future<Result<String?>> validateCredentials({
    required String school,
    required String login,
    required String passwordHash,
  }) async => const Result.success(null);

  @override
  Future<List<Student>> fetchStudents({
    required String school,
    required String login,
    required String passwordHash,
  }) async => [
    const Student(
      id: 1,
      usersEduId: 1,
      name: 'Jan',
      surname: 'Kowalski',
      sex: Sex.male,
    ),
  ];

  List<Teacher> _buildTeachers() => const [
    Teacher(
      id: 1,
      login: 'anowak',
      name: 'Anna',
      surname: 'Nowak',
      userType: 1,
    ),
    Teacher(
      id: 2,
      login: 'mkowalczyk',
      name: 'Marek',
      surname: 'Kowalczyk',
      userType: 1,
    ),
    Teacher(
      id: 3,
      login: 'ewiszniewska',
      name: 'Ewa',
      surname: 'Wiśniewska',
      userType: 1,
    ),
    Teacher(
      id: 4,
      login: 'tkaminski',
      name: 'Tomasz',
      surname: 'Kamiński',
      userType: 1,
    ),
    Teacher(
      id: 5,
      login: 'jzielinska',
      name: 'Joanna',
      surname: 'Zielińska',
      userType: 1,
    ),
    Teacher(
      id: 6,
      login: 'plewandowski',
      name: 'Piotr',
      surname: 'Lewandowski',
      userType: 1,
    ),
    Teacher(
      id: 7,
      login: 'mwojciechowska',
      name: 'Magdalena',
      surname: 'Wojciechowska',
      userType: 1,
    ),
    Teacher(
      id: 8,
      login: 'kdabrowski',
      name: 'Krzysztof',
      surname: 'Dąbrowski',
      userType: 1,
    ),
  ];

  List<Subject> _buildSubjects() => const [
    Subject(id: 1, name: 'Matematyka', abbr: 'MAT'),
    Subject(id: 2, name: 'Język polski', abbr: 'POL'),
    Subject(id: 3, name: 'Język angielski', abbr: 'ANG'),
    Subject(id: 4, name: 'Fizyka', abbr: 'FIZ'),
    Subject(id: 5, name: 'Chemia', abbr: 'CHE'),
    Subject(id: 6, name: 'Biologia', abbr: 'BIO'),
    Subject(id: 7, name: 'Historia', abbr: 'HIS'),
    Subject(id: 8, name: 'Geografia', abbr: 'GEO'),
    Subject(id: 9, name: 'Informatyka', abbr: 'INF'),
    Subject(id: 10, name: 'Wychowanie fizyczne', abbr: 'WF'),
  ];

  List<Term> _buildTerms(
    DateTime schoolYearStart,
    DateTime schoolYearEnd,
    DateTime semesterEnd,
  ) => [
    Term(
      id: 1,
      name: 'School year ${schoolYearStart.year}/${schoolYearEnd.year}',
      type: TermType.year,
      startDate: schoolYearStart,
      endDate: schoolYearEnd,
    ),
    Term(
      id: 2,
      parentId: 1,
      name: 'Semester I',
      type: TermType.semester,
      startDate: schoolYearStart,
      endDate: semesterEnd,
    ),
    Term(
      id: 3,
      parentId: 1,
      name: 'Semester II',
      type: TermType.semester,
      startDate: DateTime(semesterEnd.year, 2),
      endDate: schoolYearEnd,
    ),
  ];

  List<AttendanceType> _buildAttendanceTypes() => [
    const AttendanceType(
      id: 1,
      name: 'Present',
      abbr: 'P',
      countAs: AttendanceCountAs.present,
      excuseStatus: AttendanceExcuseStatus.unset,
    ),
    const AttendanceType(
      id: 2,
      name: 'Unexcused absence',
      abbr: 'A',
      countAs: AttendanceCountAs.absent,
      excuseStatus: AttendanceExcuseStatus.unexcused,
    ),
    const AttendanceType(
      id: 3,
      name: 'Excused absence',
      abbr: 'E',
      countAs: AttendanceCountAs.absent,
      excuseStatus: AttendanceExcuseStatus.excused,
    ),
    const AttendanceType(
      id: 4,
      name: 'Late',
      abbr: 'L',
      countAs: AttendanceCountAs.late,
      excuseStatus: AttendanceExcuseStatus.unset,
    ),
    const AttendanceType(
      id: 5,
      name: 'Released',
      abbr: 'R',
      countAs: AttendanceCountAs.other,
      excuseStatus: AttendanceExcuseStatus.excused,
    ),
  ];

  List<Attendance> _buildAttendances(
    List<ResolvedEvent> events,
    List<AttendanceType> types,
  ) {
    final rng = Random(42);
    final attendances = <Attendance>[];
    var id = 1;
    for (final event in events) {
      final roll = rng.nextInt(100);
      int typeId;
      if (roll < 85) {
        typeId = 1;
      } else if (roll < 90) {
        typeId = 2;
      } else if (roll < 94) {
        typeId = 3;
      } else if (roll < 97) {
        typeId = 4;
      } else {
        typeId = 5;
      }
      attendances.add(
        Attendance(id: id, eventsId: event.id, studentsId: 1, typesId: typeId),
      );
      id++;
    }
    return attendances;
  }
}
