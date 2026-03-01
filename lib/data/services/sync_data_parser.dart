import 'package:bsharp/domain/entities/attendance.dart';
import 'package:bsharp/domain/entities/event.dart';
import 'package:bsharp/domain/entities/mark.dart';
import 'package:bsharp/domain/entities/room.dart';
import 'package:bsharp/domain/entities/student.dart';
import 'package:bsharp/domain/entities/subject.dart';
import 'package:bsharp/domain/entities/sync_action.dart';
import 'package:bsharp/domain/entities/teacher.dart';
import 'package:bsharp/domain/entities/term.dart';

class SyncData {
  const SyncData({
    this.students = const [],
    this.teachers = const [],
    this.subjects = const [],
    this.terms = const [],
    this.rooms = const [],
    this.events = const [],
    this.eventTypes = const [],
    this.eventTypeTeachers = const [],
    this.eventTypeTerms = const [],
    this.eventSubjects = const [],
    this.marks = const [],
    this.markGroups = const [],
    this.markKinds = const [],
    this.markScales = const [],
    this.markGroupGroups = const [],
    this.attendances = const [],
    this.attendanceTypes = const [],
  });

  final List<Student> students;
  final List<Teacher> teachers;
  final List<Subject> subjects;
  final List<Term> terms;
  final List<Room> rooms;
  final List<Event> events;
  final List<EventType> eventTypes;
  final List<EventTypeTeacher> eventTypeTeachers;
  final List<EventTypeTerm> eventTypeTerms;
  final List<EventSubject> eventSubjects;
  final List<Mark> marks;
  final List<MarkGroup> markGroups;
  final List<MarkKind> markKinds;
  final List<MarkScale> markScales;
  final List<MarkGroupGroup> markGroupGroups;
  final List<Attendance> attendances;
  final List<AttendanceType> attendanceTypes;
}

class SyncDataParser {
  SyncData parse(Map<String, dynamic> data) {
    return SyncData(
      students: _parseList(data['Students'], _parseStudent),
      teachers: _parseList(data['Teachers'], _parseTeacher),
      subjects: _parseList(data['Subjects'], _parseSubject),
      terms: _parseList(data['Terms'], _parseTerm),
      rooms: _parseList(data['Rooms'], _parseRoom),
      events: _parseList(data['Events'], _parseEvent),
      eventTypes: _parseList(data['EventTypes'], _parseEventType),
      eventTypeTeachers:
          _parseList(data['EventTypeTeachers'], _parseEventTypeTeacher),
      eventTypeTerms:
          _parseList(data['EventTypeTerms'], _parseEventTypeTerm),
      eventSubjects: _parseList(data['EventSubjects'], _parseEventSubject),
      marks: _parseList(data['Marks'], _parseMark),
      markGroups: _parseList(data['MarkGroups'], _parseMarkGroup),
      markKinds: _parseList(data['MarkKinds'], _parseMarkKind),
      markScales: _parseList(data['MarkScales'], _parseMarkScale),
      markGroupGroups:
          _parseList(data['MarkGroupGroups'], _parseMarkGroupGroup),
      attendances: _parseList(data['Attendances'], _parseAttendance),
      attendanceTypes:
          _parseList(data['AttendanceTypes'], _parseAttendanceType),
    );
  }

  List<T> _parseList<T>(dynamic json, T Function(Map<String, dynamic>) mapper) {
    if (json is! List) return [];
    final result = <T>[];
    for (final item in json) {
      if (item is! Map<String, dynamic>) continue;
      final action = item['action'] as String?;
      if (action == 'D') continue;
      try {
        result.add(mapper(item));
      } on Object {
        continue;
      }
    }
    return result;
  }

  Student _parseStudent(Map<String, dynamic> j) => Student(
        id: _int(j, 'id'),
        usersEduId: _int(j, 'users_edu_id'),
        name: _str(j, 'name'),
        surname: _str(j, 'surname'),
        sex: Sex.fromString(_str(j, 'sex')),
        phone: j['phone'] as String?,
        pin: j['pin'] as String?,
      );

  Teacher _parseTeacher(Map<String, dynamic> j) => Teacher(
        id: _int(j, 'id'),
        login: _str(j, 'login'),
        usersEduId: j['users_edu_id'] as int?,
        name: _str(j, 'name'),
        surname: _str(j, 'surname'),
        phone: j['phone'] as String?,
        pin: j['pin'] as String?,
        userType: _int(j, 'user_type'),
      );

  Subject _parseSubject(Map<String, dynamic> j) => Subject(
        id: _int(j, 'id'),
        subjectsEduId: j['subjects_edu_id'] as int?,
        name: _str(j, 'name'),
        abbr: _str(j, 'abbr'),
      );

  Term _parseTerm(Map<String, dynamic> j) => Term(
        id: _int(j, 'id'),
        parentId: j['parent_id'] as int?,
        name: _str(j, 'name'),
        type: TermType.fromString(_str(j, 'type')),
        startDate: DateTime.parse(_str(j, 'start_date')),
        endDate: DateTime.parse(_str(j, 'end_date')),
      );

  Room _parseRoom(Map<String, dynamic> j) => Room(
        id: _int(j, 'id'),
        patronsId: j['patrons_id'] as int?,
        name: _str(j, 'name'),
        description: j['description'] as String?,
      );

  Event _parseEvent(Map<String, dynamic> j) => Event(
        id: _int(j, 'id'),
        name: j['name'] as String?,
        date: DateTime.parse(_str(j, 'date')),
        number: _intOrDefault(j, 'number', 0),
        startTime: _str(j, 'start_time'),
        endTime: _str(j, 'end_time'),
        roomsId: j['rooms_id'] as int?,
        eventTypesId: _int(j, 'event_types_id'),
        status: _int(j, 'status'),
        substitution: _int(j, 'substitution'),
        type: _int(j, 'type'),
        attr: _int(j, 'attr'),
        termsId: j['terms_id'] as int?,
        lessonGroupsId: j['lesson_groups_id'] as int?,
        locked: _int(j, 'locked'),
      );

  EventType _parseEventType(Map<String, dynamic> j) => EventType(
        id: _int(j, 'id'),
        subjectsId: j['subjects_id'] as int?,
        teachingLevel: _int(j, 'teaching_level'),
        substitution: _int(j, 'substitution'),
      );

  EventTypeTeacher _parseEventTypeTeacher(Map<String, dynamic> j) =>
      EventTypeTeacher(
        id: _int(j, 'id'),
        teachersId: _int(j, 'teachers_id'),
        eventTypesId: _int(j, 'event_types_id'),
      );

  EventSubject _parseEventSubject(Map<String, dynamic> j) => EventSubject(
        id: _int(j, 'id'),
        eventsId: _int(j, 'events_id'),
        content: _str(j, 'content'),
        addTime: _dateTimeOrNull(j['add_time']),
      );

  Mark _parseMark(Map<String, dynamic> j) => Mark(
        id: _int(j, 'id'),
        markGroupsId: _int(j, 'mark_groups_id'),
        markScalesId: j['mark_scales_id'] as int?,
        pupilUsersId: _int(j, 'pupil_users_id'),
        teacherUsersId: _int(j, 'teacher_users_id'),
        markValue: _doubleOrNull(j['mark_value']),
        comments: j['comments'] as String?,
        weight: _intOrDefault(j, 'weight', 1),
        getDate: DateTime.parse(_str(j, 'get_date')),
        addTime: _dateTimeOrNull(j['add_time']),
        modified: _intOrDefault(j, 'modified', 0),
        eventsId: j['events_id'] as int?,
      );

  MarkGroup _parseMarkGroup(Map<String, dynamic> j) => MarkGroup(
        id: _int(j, 'id'),
        parentId: j['parent_id'] as int?,
        parentType: j['parent_type'] as int?,
        markGroupGroupsId: j['mark_group_groups_id'] as int?,
        isPattern: _int(j, 'is_pattern'),
        eventTypeTermsId: j['event_type_terms_id'] as int?,
        markKindsId: j['mark_kinds_id'] as int?,
        abbreviation: j['abbreviation'] as String?,
        description: j['description'] as String?,
        markType: _int(j, 'mark_type'),
        markFormat: j['mark_format'] as String?,
        markDivisionGroupsId: j['mark_division_groups_id'] as int?,
        markScaleGroupsId: j['mark_scale_groups_id'] as int?,
        visibility: _intOrDefault(j, 'visibility', 1),
        cssStyle: j['css_style'] as String?,
        position: _intOrDefault(j, 'position', 0),
        weight: _intOrDefault(j, 'weight', 1),
        markValueRangeMin: _doubleOrNull(j['mark_value_range_min']),
        markValueRangeMax: _doubleOrNull(j['mark_value_range_max']),
        precision: _doubleOrNull(j['precision']),
        addByUsersId: j['add_by_users_id'] as int?,
      );

  MarkKind _parseMarkKind(Map<String, dynamic> j) => MarkKind(
        id: _int(j, 'id'),
        parentId: j['parent_id'] as int?,
        name: _str(j, 'name'),
        abbreviation: _str(j, 'abbreviation'),
        subjectsId: j['subjects_id'] as int?,
        public: _int(j, 'public'),
        addByUsersId: j['add_by_users_id'] as int?,
        defaultMarkType: _intOrDefault(j, 'default_mark_type', 0),
        defaultMarkScaleGroupsId: j['default_mark_scale_groups_id'] as int?,
        defaultMarkDivisionGroupsId:
            j['default_mark_division_groups_id'] as int?,
        defaultWeight: _intOrDefault(j, 'default_weigth', 1),
        position: _int(j, 'position'),
        cssStyle: j['css_style'] as String?,
      );

  MarkScale _parseMarkScale(Map<String, dynamic> j) => MarkScale(
        id: _int(j, 'id'),
        markScaleGroupsId: _int(j, 'mark_scale_groups_id'),
        abbreviation: _str(j, 'abbreviation'),
        name: _str(j, 'name'),
        markValue: _doubleOrNull(j['mark_value']),
        image: j['image'] as String?,
        classified: _int(j, 'classified'),
        noCountToAverage: _int(j, 'no_count_to_average'),
        cssStyle: j['css_style'] as String?,
        markScaleEduId: j['mark_scale_edu_id'] as int?,
      );

  MarkGroupGroup _parseMarkGroupGroup(Map<String, dynamic> j) =>
      MarkGroupGroup(
        id: _int(j, 'id'),
        markDivisionGroupsId: j['mark_division_groups_id'] as int?,
        name: _str(j, 'name'),
        parentId: j['parent_id'] as int?,
        isPattern: _intOrDefault(j, 'is_pattern', 0),
        position: _intOrDefault(j, 'position', 0),
        weight: _intOrDefault(j, 'weight', 1),
      );

  EventTypeTerm _parseEventTypeTerm(Map<String, dynamic> j) => EventTypeTerm(
        id: _int(j, 'id'),
        termsId: _int(j, 'terms_id'),
        eventTypesId: _int(j, 'event_types_id'),
      );

  Attendance _parseAttendance(Map<String, dynamic> j) => Attendance(
        id: _int(j, 'id'),
        eventsId: _int(j, 'events_id'),
        studentsId: _int(j, 'students_id'),
        typesId: _int(j, 'types_id'),
      );

  AttendanceType _parseAttendanceType(Map<String, dynamic> j) =>
      AttendanceType(
        id: _int(j, 'id'),
        name: _str(j, 'name'),
        abbr: _str(j, 'abbr'),
        style: j['style'] as String?,
        countAs: AttendanceCountAs.fromString(_str(j, 'count_as')),
        excuseStatus:
            AttendanceExcuseStatus.fromString(j['type'] as String?),
      );

  int _int(Map<String, dynamic> j, String key) => j[key] as int;

  int _intOrDefault(Map<String, dynamic> j, String key, int defaultValue) =>
      (j[key] as int?) ?? defaultValue;

  String _str(Map<String, dynamic> j, String key) => j[key] as String;

  double? _doubleOrNull(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  DateTime? _dateTimeOrNull(dynamic v) {
    if (v == null) return null;
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
    return null;
  }
}
