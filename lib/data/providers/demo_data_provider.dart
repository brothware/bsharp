import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bsharp/app/child_provider.dart';
import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/domain/entities/attendance.dart';
import 'package:bsharp/domain/entities/event.dart';
import 'package:bsharp/domain/entities/mark.dart';
import 'package:bsharp/domain/entities/poczta.dart';
import 'package:bsharp/domain/entities/portal.dart';
import 'package:bsharp/domain/entities/room.dart';
import 'package:bsharp/domain/entities/student.dart';
import 'package:bsharp/domain/entities/subject.dart';
import 'package:bsharp/domain/entities/sync_action.dart';
import 'package:bsharp/domain/entities/teacher.dart';
import 'package:bsharp/domain/entities/term.dart';
import 'package:bsharp/domain/school_data_provider.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/attendance/providers/attendance_providers.dart';
import 'package:bsharp/presentation/grades/providers/grades_providers.dart';
import 'package:bsharp/presentation/messages/providers/messages_providers.dart';
import 'package:bsharp/presentation/more/providers/more_providers.dart';
import 'package:bsharp/presentation/schedule/providers/schedule_providers.dart';

String _l({required String pl, required String en}) {
  final locale = LocaleSettings.currentLocale;
  return locale == AppLocale.pl ? pl : en;
}

String _date(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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
  Future<void> loadSchoolData(Ref ref, {required int studentId}) async {
    final now = DateTime.now();
    final schoolYearStart = now.month >= 9
        ? DateTime(now.year, 9, 1)
        : DateTime(now.year - 1, 9, 1);
    final schoolYearEnd = DateTime(schoolYearStart.year + 1, 6, 30);
    final semesterEnd = DateTime(schoolYearStart.year + 1, 1, 31);

    ref.read(studentsProvider.notifier).state = [
      const Student(
        id: 1,
        usersEduId: 1,
        name: 'Jan',
        surname: 'Kowalski',
        sex: Sex.male,
      ),
    ];

    final teachers = _buildTeachers();
    ref.read(teachersProvider.notifier).state = teachers;

    final subjects = _buildSubjects();
    ref.read(subjectsProvider.notifier).state = subjects;

    ref.read(roomsProvider.notifier).state = _buildRooms();

    final terms = _buildTerms(schoolYearStart, schoolYearEnd, semesterEnd);
    ref.read(termsProvider.notifier).state = terms;

    final eventTypes = _buildEventTypes(subjects, teachers);
    ref.read(eventTypesProvider.notifier).state = eventTypes
        .map((e) => e.eventType)
        .toList();
    ref.read(eventTypeTeachersProvider.notifier).state = eventTypes
        .map((e) => e.eventTypeTeacher)
        .toList();
    ref.read(eventTypeTermsProvider.notifier).state = eventTypes
        .map((e) => e.eventTypeTerm)
        .toList();

    final events = _buildEvents(now, eventTypes);
    ref.read(eventsProvider.notifier).state = events;
    ref.read(eventSubjectsProvider.notifier).state = _buildEventSubjects(
      events,
    );
    ref.read(eventEventsProvider.notifier).state = [];

    final markScales = _buildMarkScales();
    ref.read(markScalesProvider.notifier).state = markScales;

    final markKinds = _buildMarkKinds();
    ref.read(markKindsProvider.notifier).state = markKinds;

    final markGroupGroups = _buildMarkGroupGroups(subjects);
    ref.read(markGroupGroupsProvider.notifier).state = markGroupGroups;

    final markGroups = _buildMarkGroups(eventTypes, markKinds, markGroupGroups);
    ref.read(markGroupsProvider.notifier).state = markGroups;

    ref.read(marksProvider.notifier).state = _buildMarks(
      markGroups,
      markScales,
      teachers,
    );

    final attendanceTypes = _buildAttendanceTypes();
    ref.read(attendanceTypesProvider.notifier).state = attendanceTypes;

    ref.read(attendancesProvider.notifier).state = _buildAttendances(
      events,
      attendanceTypes,
    );

    ref.read(homeworksProvider.notifier).state = _buildHomeworks(now);
    ref.read(testsProvider.notifier).state = _buildTests(now);
    ref.read(reprimandsProvider.notifier).state = _buildReprimands(
      now,
      teachers,
    );
    ref.read(bulletinsProvider.notifier).state = _buildBulletins(now);
    ref.read(gradeChangelogProvider.notifier).state = _buildChangelog(now);
    ref.read(attendanceChangelogProvider.notifier).state = [];
  }

  @override
  Future<void> loadMessages(Ref ref) async {
    final now = DateTime.now();
    ref.read(inboxProvider.notifier).state = _buildInbox(now);
    ref.read(sentProvider.notifier).state = _buildSent(now);
    ref.read(trashProvider.notifier).state = _buildTrash(now);
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
  String hashPassword(String password) => '';

  @override
  Future<Result<void>> validateCredentials({
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

  List<Teacher> _buildTeachers() => [
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

  List<Subject> _buildSubjects() => [
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

  List<Room> _buildRooms() => const [
    Room(id: 1, name: '101'),
    Room(id: 2, name: '205'),
    Room(id: 3, name: '112'),
    Room(id: 4, name: '301'),
    Room(id: 5, name: '015'),
    Room(id: 6, name: 'Sala gimnastyczna'),
  ];

  List<Term> _buildTerms(
    DateTime schoolYearStart,
    DateTime schoolYearEnd,
    DateTime semesterEnd,
  ) => [
    Term(
      id: 1,
      name: _l(
        pl: 'Rok szkolny ${schoolYearStart.year}/${schoolYearEnd.year}',
        en: 'School year ${schoolYearStart.year}/${schoolYearEnd.year}',
      ),
      type: TermType.year,
      startDate: schoolYearStart,
      endDate: schoolYearEnd,
    ),
    Term(
      id: 2,
      parentId: 1,
      name: _l(pl: 'Semestr I', en: 'Semester I'),
      type: TermType.semester,
      startDate: schoolYearStart,
      endDate: semesterEnd,
    ),
    Term(
      id: 3,
      parentId: 1,
      name: _l(pl: 'Semestr II', en: 'Semester II'),
      type: TermType.semester,
      startDate: DateTime(semesterEnd.year, 2, 1),
      endDate: schoolYearEnd,
    ),
  ];

  List<_EventTypeBundle> _buildEventTypes(
    List<Subject> subjects,
    List<Teacher> teachers,
  ) {
    final teacherAssignment = [1, 2, 3, 4, 5, 6, 7, 8, 1, 6];
    return [
      for (var i = 0; i < subjects.length; i++)
        _EventTypeBundle(
          eventType: EventType(
            id: i + 1,
            subjectsId: subjects[i].id,
            teachingLevel: 0,
            substitution: 0,
          ),
          eventTypeTeacher: EventTypeTeacher(
            id: i + 1,
            teachersId: teacherAssignment[i],
            eventTypesId: i + 1,
          ),
          eventTypeTerm: EventTypeTerm(
            id: i + 1,
            termsId: 3,
            eventTypesId: i + 1,
          ),
        ),
    ];
  }

  List<Event> _buildEvents(DateTime now, List<_EventTypeBundle> eventTypes) {
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final bellTimes = [
      ('08:00', '08:45'),
      ('08:55', '09:40'),
      ('09:50', '10:35'),
      ('10:55', '11:40'),
      ('11:50', '12:35'),
      ('12:45', '13:30'),
      ('13:40', '14:25'),
    ];
    final schedule = <List<int>>[
      [1, 2, 3, 7, 4, 10, 9],
      [2, 1, 5, 6, 3, 8, 10],
      [3, 4, 1, 2, 6, 5, 7],
      [1, 7, 8, 3, 9, 2, 4],
      [2, 3, 1, 10, 5, 6, 8],
    ];
    final rooms = [1, 2, 3, 4, 5, 1, 6];

    final events = <Event>[];
    var eventId = 1;
    for (var dayIdx = 0; dayIdx < 5; dayIdx++) {
      final date = monday.add(Duration(days: dayIdx));
      final daySchedule = schedule[dayIdx];
      for (var lessonIdx = 0; lessonIdx < daySchedule.length; lessonIdx++) {
        final subjectIdx = daySchedule[lessonIdx] - 1;
        events.add(
          Event(
            id: eventId,
            date: DateTime(date.year, date.month, date.day),
            number: lessonIdx + 1,
            startTime: bellTimes[lessonIdx].$1,
            endTime: bellTimes[lessonIdx].$2,
            roomsId: rooms[lessonIdx],
            eventTypesId: eventTypes[subjectIdx].eventType.id,
            status: 1,
            substitution: 0,
            type: 0,
            attr: 0,
            locked: 1,
          ),
        );
        eventId++;
      }
    }
    return events;
  }

  List<EventSubject> _buildEventSubjects(List<Event> events) {
    final topics = {
      1: _l(pl: 'Równania kwadratowe', en: 'Quadratic equations'),
      2: _l(pl: 'Analiza wiersza', en: 'Poem analysis'),
      3: _l(pl: 'Present Perfect Tense', en: 'Present Perfect Tense'),
      4: _l(pl: 'Prawa dynamiki Newtona', en: "Newton's laws of motion"),
      9: _l(pl: 'Pętle w Pythonie', en: 'Loops in Python'),
    };

    final result = <EventSubject>[];
    var id = 1;
    for (final event in events) {
      final topic = topics[event.eventTypesId];
      if (topic != null && event.number <= 2) {
        result.add(EventSubject(id: id, eventsId: event.id, content: topic));
        id++;
      }
    }
    return result;
  }

  List<MarkScale> _buildMarkScales() {
    final grades = [
      (1, '1', _l(pl: 'niedostateczny', en: 'failing'), 1.0),
      (2, '2', _l(pl: 'dopuszczający', en: 'poor'), 2.0),
      (3, '3', _l(pl: 'dostateczny', en: 'satisfactory'), 3.0),
      (4, '4', _l(pl: 'dobry', en: 'good'), 4.0),
      (5, '5', _l(pl: 'bardzo dobry', en: 'very good'), 5.0),
      (6, '6', _l(pl: 'celujący', en: 'excellent'), 6.0),
    ];
    return [
      for (final (id, abbr, name, value) in grades)
        MarkScale(
          id: id,
          markScaleGroupsId: 1,
          abbreviation: abbr,
          name: name,
          markValue: value,
          classified: 1,
          noCountToAverage: 0,
        ),
    ];
  }

  List<MarkKind> _buildMarkKinds() => [
    MarkKind(
      id: 1,
      name: _l(pl: 'Sprawdzian', en: 'Exam'),
      abbreviation: 'Spr',
      public: 1,
      defaultMarkType: 0,
      defaultWeight: 3,
      position: 1,
    ),
    MarkKind(
      id: 2,
      name: _l(pl: 'Kartkówka', en: 'Quiz'),
      abbreviation: 'Kar',
      public: 1,
      defaultMarkType: 0,
      defaultWeight: 2,
      position: 2,
    ),
    MarkKind(
      id: 3,
      name: _l(pl: 'Odpowiedź ustna', en: 'Oral answer'),
      abbreviation: 'Odp',
      public: 1,
      defaultMarkType: 0,
      defaultWeight: 2,
      position: 3,
    ),
    MarkKind(
      id: 4,
      name: _l(pl: 'Praca domowa', en: 'Homework'),
      abbreviation: 'PD',
      public: 1,
      defaultMarkType: 0,
      defaultWeight: 1,
      position: 4,
    ),
    MarkKind(
      id: 5,
      name: _l(pl: 'Aktywność', en: 'Activity'),
      abbreviation: 'Akt',
      public: 1,
      defaultMarkType: 0,
      defaultWeight: 1,
      position: 5,
    ),
  ];

  List<MarkGroupGroup> _buildMarkGroupGroups(List<Subject> subjects) => [
    for (var i = 0; i < subjects.length; i++)
      MarkGroupGroup(
        id: i + 1,
        name: subjects[i].name,
        isPattern: 0,
        position: i,
      ),
  ];

  List<MarkGroup> _buildMarkGroups(
    List<_EventTypeBundle> eventTypes,
    List<MarkKind> markKinds,
    List<MarkGroupGroup> markGroupGroups,
  ) {
    final groups = <MarkGroup>[];
    var id = 1;
    for (var subIdx = 0; subIdx < eventTypes.length; subIdx++) {
      for (final kind in markKinds) {
        groups.add(
          MarkGroup(
            id: id,
            markGroupGroupsId: markGroupGroups[subIdx].id,
            isPattern: 0,
            eventTypeTermsId: eventTypes[subIdx].eventTypeTerm.id,
            markKindsId: kind.id,
            markType: 0,
            markScaleGroupsId: 1,
            visibility: 1,
            position: kind.position,
            weight: kind.defaultWeight,
          ),
        );
        id++;
      }
    }
    return groups;
  }

  List<Mark> _buildMarks(
    List<MarkGroup> markGroups,
    List<MarkScale> markScales,
    List<Teacher> teachers,
  ) {
    final rng = Random(42);
    final now = DateTime.now();
    final marks = <Mark>[];
    var id = 1;

    final gradeValues = [
      3,
      4,
      5,
      4,
      3,
      5,
      4,
      6,
      3,
      4,
      5,
      2,
      4,
      5,
      3,
      4,
      5,
      4,
      3,
      5,
      4,
      5,
      6,
      3,
      4,
      5,
      4,
      3,
      5,
      4,
    ];

    for (var i = 0; i < gradeValues.length && i < markGroups.length; i++) {
      final gradeVal = gradeValues[i];
      final scale = markScales.firstWhere(
        (s) => s.markValue == gradeVal.toDouble(),
      );
      final group = markGroups[i];
      final daysAgo = rng.nextInt(60) + 1;

      marks.add(
        Mark(
          id: id,
          markGroupsId: group.id,
          markScalesId: scale.id,
          pupilUsersId: 1,
          teacherUsersId: teachers[rng.nextInt(teachers.length)].id,
          markValue: scale.markValue,
          weight: group.weight,
          getDate: now.subtract(Duration(days: daysAgo)),
          modified: 0,
        ),
      );
      id++;
    }
    return marks;
  }

  List<AttendanceType> _buildAttendanceTypes() => [
    const AttendanceType(
      id: 1,
      name: 'Obecność',
      abbr: 'ob',
      countAs: AttendanceCountAs.present,
      excuseStatus: AttendanceExcuseStatus.unset,
    ),
    const AttendanceType(
      id: 2,
      name: 'Nieobecność nieusprawiedliwiona',
      abbr: 'nb',
      countAs: AttendanceCountAs.absent,
      excuseStatus: AttendanceExcuseStatus.unexcused,
    ),
    const AttendanceType(
      id: 3,
      name: 'Nieobecność usprawiedliwiona',
      abbr: 'u',
      countAs: AttendanceCountAs.absent,
      excuseStatus: AttendanceExcuseStatus.excused,
    ),
    const AttendanceType(
      id: 4,
      name: 'Spóźnienie',
      abbr: 'sp',
      countAs: AttendanceCountAs.late,
      excuseStatus: AttendanceExcuseStatus.unset,
    ),
    const AttendanceType(
      id: 5,
      name: 'Zwolnienie',
      abbr: 'zw',
      countAs: AttendanceCountAs.other,
      excuseStatus: AttendanceExcuseStatus.excused,
    ),
  ];

  List<Attendance> _buildAttendances(
    List<Event> events,
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

  List<PortalHomework> _buildHomeworks(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return [
      PortalHomework(
        id: 1,
        subjectName: 'Matematyka',
        date: _date(today.subtract(const Duration(days: 2))),
        dueDate: _date(today.add(const Duration(days: 1))),
        content: _l(
          pl: 'Zadania 1-10 ze strony 95',
          en: 'Exercises 1-10 from page 95',
        ),
      ),
      PortalHomework(
        id: 2,
        subjectName: 'Język polski',
        date: _date(today.subtract(const Duration(days: 1))),
        dueDate: _date(today.add(const Duration(days: 3))),
        content: _l(
          pl: 'Napisz rozprawkę na temat "Czy warto czytać książki?"',
          en: 'Write an essay on "Is it worth reading books?"',
        ),
      ),
      PortalHomework(
        id: 3,
        subjectName: 'Język angielski',
        date: _date(today),
        dueDate: _date(today.add(const Duration(days: 5))),
        content: _l(
          pl: 'Ćwiczenia z unit 5, strony 48-49',
          en: 'Unit 5 exercises, pages 48-49',
        ),
      ),
      PortalHomework(
        id: 4,
        subjectName: 'Fizyka',
        date: _date(today.subtract(const Duration(days: 7))),
        dueDate: _date(today.subtract(const Duration(days: 2))),
        content: _l(
          pl: 'Zadania z dynamiki — zestaw nr 3',
          en: 'Dynamics problem set #3',
        ),
      ),
    ];
  }

  List<PortalTest> _buildTests(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return [
      PortalTest(
        id: 1,
        subjectName: 'Matematyka',
        date: _date(today.add(const Duration(days: 2))),
        title: _l(pl: 'Funkcje kwadratowe', en: 'Quadratic functions'),
      ),
      PortalTest(
        id: 2,
        subjectName: 'Historia',
        date: _date(today.add(const Duration(days: 4))),
        title: _l(pl: 'II wojna światowa', en: 'World War II'),
      ),
      PortalTest(
        id: 3,
        subjectName: 'Chemia',
        date: _date(today.add(const Duration(days: 6))),
        title: _l(pl: 'Reakcje chemiczne', en: 'Chemical reactions'),
      ),
    ];
  }

  List<PortalReprimand> _buildReprimands(DateTime now, List<Teacher> teachers) {
    final today = DateTime(now.year, now.month, now.day);
    return [
      PortalReprimand(
        id: 1,
        date: _date(today.subtract(const Duration(days: 5))),
        teacherName: '${teachers[0].name} ${teachers[0].surname}',
        content: _l(
          pl: 'Wzorowe zachowanie podczas wycieczki szkolnej',
          en: 'Exemplary behaviour during school trip',
        ),
        type: 1,
      ),
      PortalReprimand(
        id: 2,
        date: _date(today.subtract(const Duration(days: 10))),
        teacherName: '${teachers[1].name} ${teachers[1].surname}',
        content: _l(pl: 'Rozmowa podczas lekcji', en: 'Talking during class'),
        type: 2,
      ),
      PortalReprimand(
        id: 3,
        date: _date(today.subtract(const Duration(days: 15))),
        teacherName: '${teachers[2].name} ${teachers[2].surname}',
        content: _l(
          pl: 'Udział w konkursie matematycznym — reprezentowanie szkoły',
          en: 'Participation in maths competition — representing school',
        ),
        type: 0,
      ),
    ];
  }

  List<PortalBulletin> _buildBulletins(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return [
      PortalBulletin(
        id: 1,
        title: _l(
          pl: 'Wywiadówka — 15 marca',
          en: 'Parent-teacher meeting — March 15',
        ),
        content: '',
        date: _date(today.subtract(const Duration(days: 3))),
        author: 'Dyrekcja',
        isRead: true,
      ),
      PortalBulletin(
        id: 2,
        title: _l(pl: 'Dni wolne od zajęć — Wielkanoc', en: 'Easter holidays'),
        content: '',
        date: _date(today.subtract(const Duration(days: 1))),
        author: 'Dyrekcja',
        isRead: false,
      ),
    ];
  }

  List<PortalChangelog> _buildChangelog(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return [
      PortalChangelog(
        type: 'mark',
        dateTime: today.subtract(const Duration(days: 1)).toIso8601String(),
        subjectName: 'Matematyka',
        user: 'Anna Nowak',
        newName: '5',
        action: 'add',
      ),
      PortalChangelog(
        type: 'mark',
        dateTime: today.subtract(const Duration(days: 2)).toIso8601String(),
        subjectName: 'Język polski',
        user: 'Marek Kowalczyk',
        newName: '4',
        action: 'add',
      ),
      PortalChangelog(
        type: 'mark',
        dateTime: today.subtract(const Duration(days: 3)).toIso8601String(),
        subjectName: 'Fizyka',
        user: 'Tomasz Kamiński',
        newName: '3+',
        newAdditionalInfo: '3',
        action: 'update',
      ),
      PortalChangelog(
        type: 'mark',
        dateTime: today.subtract(const Duration(days: 4)).toIso8601String(),
        subjectName: 'Język angielski',
        user: 'Ewa Wiśniewska',
        newName: '5',
        action: 'add',
      ),
      PortalChangelog(
        type: 'mark',
        dateTime: today.subtract(const Duration(days: 5)).toIso8601String(),
        subjectName: 'Biologia',
        user: 'Joanna Zielińska',
        newName: '4',
        action: 'add',
      ),
    ];
  }

  List<PocztaMessage> _buildInbox(DateTime now) => [
    PocztaMessage(
      id: 1,
      title: _l(pl: 'Wycieczka klasowa', en: 'Class trip'),
      senderName: 'Anna Nowak',
      sendTime: now.subtract(const Duration(hours: 2)),
      isRead: false,
      isStarred: false,
      content: _l(
        pl: 'Szanowni Państwo, informuję o planowanej wycieczce klasowej do Muzeum Narodowego w dniu 20 marca. Proszę o wyrażenie zgody.',
        en: 'Dear parents, I am informing you about the planned class trip to the National Museum on March 20. Please provide your consent.',
      ),
    ),
    PocztaMessage(
      id: 2,
      title: _l(pl: 'Oceny semestralne', en: 'Semester grades'),
      senderName: 'Marek Kowalczyk',
      sendTime: now.subtract(const Duration(hours: 5)),
      isRead: false,
      isStarred: true,
      content: _l(
        pl: 'Informuję, że oceny semestralne zostały wystawione. Proszę o zapoznanie się z wynikami w dzienniku elektronicznym.',
        en: 'I am informing you that semester grades have been issued. Please review the results in the e-gradebook.',
      ),
    ),
    PocztaMessage(
      id: 3,
      title: _l(pl: 'Konkurs matematyczny', en: 'Maths competition'),
      senderName: 'Anna Nowak',
      sendTime: now.subtract(const Duration(days: 1)),
      isRead: true,
      isStarred: false,
      content: _l(
        pl: 'Jan został zakwalifikowany do etapu szkolnego konkursu matematycznego. Gratulacje!',
        en: 'Jan has been qualified for the school stage of the maths competition. Congratulations!',
      ),
    ),
    PocztaMessage(
      id: 4,
      title: _l(pl: 'Zebranie rodziców', en: 'Parent meeting'),
      senderName: 'Dyrekcja',
      sendTime: now.subtract(const Duration(days: 2)),
      isRead: true,
      isStarred: false,
      content: _l(
        pl: 'Zapraszamy na zebranie rodziców w dniu 15 marca o godz. 17:00.',
        en: 'We invite you to the parent meeting on March 15 at 5:00 PM.',
      ),
    ),
    PocztaMessage(
      id: 5,
      title: _l(
        pl: 'Zadanie dodatkowe z fizyki',
        en: 'Extra physics assignment',
      ),
      senderName: 'Tomasz Kamiński',
      sendTime: now.subtract(const Duration(days: 3)),
      isRead: true,
      isStarred: false,
      content: _l(
        pl: 'Dla chętnych: dodatkowe zadania z dynamiki na ocenę celującą.',
        en: 'For volunteers: extra dynamics problems for an excellent grade.',
      ),
    ),
    PocztaMessage(
      id: 6,
      title: _l(pl: 'Ubezpieczenie szkolne', en: 'School insurance'),
      senderName: 'Sekretariat',
      sendTime: now.subtract(const Duration(days: 5)),
      isRead: true,
      isStarred: false,
      content: _l(
        pl: 'Przypominamy o opłaceniu ubezpieczenia szkolnego do końca miesiąca.',
        en: 'Please remember to pay the school insurance by the end of the month.',
      ),
    ),
  ];

  List<PocztaMessage> _buildSent(DateTime now) => [
    PocztaMessage(
      id: 101,
      title: _l(pl: 'Re: Wycieczka klasowa', en: 'Re: Class trip'),
      senderName: 'Jan Kowalski',
      sendTime: now.subtract(const Duration(hours: 1)),
      isRead: true,
      isStarred: false,
      content: _l(
        pl: 'Wyrażam zgodę na udział mojego dziecka w wycieczce.',
        en: 'I consent to my child participating in the trip.',
      ),
    ),
    PocztaMessage(
      id: 102,
      title: _l(pl: 'Pytanie o ocenę', en: 'Question about grade'),
      senderName: 'Jan Kowalski',
      sendTime: now.subtract(const Duration(days: 1)),
      isRead: true,
      isStarred: false,
      content: _l(
        pl: 'Czy jest możliwość poprawy oceny ze sprawdzianu?',
        en: 'Is it possible to retake the exam for a better grade?',
      ),
    ),
  ];

  List<PocztaMessage> _buildTrash(DateTime now) => [
    PocztaMessage(
      id: 201,
      title: _l(pl: 'Newsletter szkolny', en: 'School newsletter'),
      senderName: 'Sekretariat',
      sendTime: now.subtract(const Duration(days: 10)),
      isRead: true,
      isStarred: false,
      content: _l(
        pl: 'Najnowszy newsletter szkolny.',
        en: 'The latest school newsletter.',
      ),
    ),
  ];
}

class _EventTypeBundle {
  const _EventTypeBundle({
    required this.eventType,
    required this.eventTypeTeacher,
    required this.eventTypeTerm,
  });

  final EventType eventType;
  final EventTypeTeacher eventTypeTeacher;
  final EventTypeTerm eventTypeTerm;
}
