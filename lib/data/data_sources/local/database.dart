import 'package:drift/drift.dart';

part 'database.g.dart';

class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get school => text()();
  TextColumn get login => text()();
  TextColumn get passwordHash => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

class SyncMetadata extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get accountId => integer().references(Accounts, #id)();
  IntColumn get studentId => integer()();
  TextColumn get databaseSnapshotId => text().nullable()();
  DateTimeColumn get lastSyncTime => dateTime().nullable()();
  TextColumn get lastEndDate => text().nullable()();
}

class Students extends Table {
  IntColumn get id => integer()();
  IntColumn get usersEduId => integer()();
  TextColumn get name => text()();
  TextColumn get surname => text()();
  TextColumn get sex => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get pin => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Teachers extends Table {
  IntColumn get id => integer()();
  TextColumn get login => text()();
  IntColumn get usersEduId => integer()();
  TextColumn get name => text()();
  TextColumn get surname => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get pin => text().nullable()();
  IntColumn get userType => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class Subjects extends Table {
  IntColumn get id => integer()();
  IntColumn get subjectsEduId => integer()();
  TextColumn get name => text()();
  TextColumn get abbr => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class Groups extends Table {
  IntColumn get id => integer()();
  IntColumn get parentId => integer().nullable()();
  IntColumn get groupsEduId => integer()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  TextColumn get attr => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Terms extends Table {
  IntColumn get id => integer()();
  IntColumn get parentId => integer().nullable()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Rooms extends Table {
  IntColumn get id => integer()();
  IntColumn get patronsId => integer().nullable()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Events extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text().nullable()();
  DateTimeColumn get date => dateTime()();
  IntColumn get number => integer()();
  TextColumn get startTime => text()();
  TextColumn get endTime => text()();
  IntColumn get roomsId => integer().nullable()();
  IntColumn get eventTypesId => integer()();
  IntColumn get status => integer()();
  IntColumn get substitution => integer()();
  IntColumn get type => integer()();
  IntColumn get attr => integer()();
  IntColumn get termsId => integer().nullable()();
  IntColumn get lessonGroupsId => integer().nullable()();
  IntColumn get locked => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class EventTypes extends Table {
  IntColumn get id => integer()();
  IntColumn get subjectsId => integer()();
  IntColumn get teachingLevel => integer()();
  IntColumn get substitution => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class EventTypeTeachers extends Table {
  IntColumn get id => integer()();
  IntColumn get teachersId => integer()();
  IntColumn get eventTypesId => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class EventTypeGroups extends Table {
  IntColumn get id => integer()();
  IntColumn get groupsId => integer()();
  IntColumn get eventTypesId => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class EventTypeTerms extends Table {
  IntColumn get id => integer()();
  IntColumn get termsId => integer()();
  IntColumn get eventTypesId => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class EventSubjects extends Table {
  IntColumn get id => integer()();
  IntColumn get eventsId => integer()();
  TextColumn get content => text()();
  DateTimeColumn get addTime => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class EventIssues extends Table {
  IntColumn get id => integer()();
  IntColumn get eventsId => integer()();
  IntColumn get eventTypesId => integer()();
  IntColumn get issuesId => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class EventEvents extends Table {
  IntColumn get id => integer()();
  IntColumn get events1Id => integer()();
  IntColumn get events2Id => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class EventTypeSchedules extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get eventTypesId => integer()();
  IntColumn get schedulesId => integer()();
  TextColumn get name => text()();
  TextColumn get number => text()();
}

class LessonGroups extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  IntColumn get selected => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class Lessons extends Table {
  IntColumn get id => integer()();
  IntColumn get lessonGroupsId => integer()();
  IntColumn get lessonNumber => integer()();
  TextColumn get startTime => text()();
  TextColumn get endTime => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class Marks extends Table {
  IntColumn get id => integer()();
  IntColumn get markGroupsId => integer()();
  IntColumn get markScalesId => integer().nullable()();
  IntColumn get pupilUsersId => integer()();
  IntColumn get teacherUsersId => integer()();
  RealColumn get markValue => real().nullable()();
  TextColumn get comments => text().nullable()();
  IntColumn get weight => integer()();
  DateTimeColumn get getDate => dateTime()();
  DateTimeColumn get addTime => dateTime().nullable()();
  IntColumn get modified => integer()();
  IntColumn get eventsId => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class MarkGroupsTable extends Table {
  @override
  String get tableName => 'mark_groups';

  IntColumn get id => integer()();
  IntColumn get parentId => integer().nullable()();
  IntColumn get parentType => integer().nullable()();
  IntColumn get markGroupGroupsId => integer().nullable()();
  IntColumn get isPattern => integer()();
  IntColumn get eventTypeTermsId => integer().nullable()();
  IntColumn get markKindsId => integer().nullable()();
  TextColumn get abbreviation => text().nullable()();
  TextColumn get description => text().nullable()();
  IntColumn get markType => integer()();
  TextColumn get markFormat => text().nullable()();
  IntColumn get markDivisionGroupsId => integer().nullable()();
  IntColumn get markScaleGroupsId => integer().nullable()();
  IntColumn get visibility => integer()();
  TextColumn get cssStyle => text().nullable()();
  IntColumn get position => integer()();
  IntColumn get weight => integer()();
  RealColumn get markValueRangeMin => real().nullable()();
  RealColumn get markValueRangeMax => real().nullable()();
  RealColumn get precision => real().nullable()();
  IntColumn get addByUsersId => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class MarkKinds extends Table {
  IntColumn get id => integer()();
  IntColumn get parentId => integer().nullable()();
  TextColumn get name => text()();
  TextColumn get abbreviation => text()();
  IntColumn get subjectsId => integer().nullable()();
  IntColumn get public => integer()();
  IntColumn get addByUsersId => integer().nullable()();
  IntColumn get defaultMarkType => integer()();
  IntColumn get defaultMarkScaleGroupsId => integer().nullable()();
  IntColumn get defaultMarkDivisionGroupsId => integer().nullable()();
  IntColumn get defaultWeight => integer()();
  IntColumn get position => integer()();
  TextColumn get cssStyle => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class MarkScaleGroupsTable extends Table {
  @override
  String get tableName => 'mark_scale_groups';

  IntColumn get id => integer()();
  TextColumn get name => text()();
  IntColumn get public => integer()();
  IntColumn get addByUsersId => integer().nullable()();
  TextColumn get markTypes => text().nullable()();
  IntColumn get markScaleGroupEduId => integer().nullable()();
  IntColumn get isSystem => integer()();
  IntColumn get isDefault => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class MarkScales extends Table {
  IntColumn get id => integer()();
  IntColumn get markScaleGroupsId => integer()();
  TextColumn get abbreviation => text()();
  TextColumn get name => text()();
  RealColumn get markValue => real().nullable()();
  TextColumn get image => text().nullable()();
  IntColumn get classified => integer()();
  IntColumn get noCountToAverage => integer()();
  TextColumn get cssStyle => text().nullable()();
  IntColumn get markScaleEduId => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class MarkDivisionGroupsTable extends Table {
  @override
  String get tableName => 'mark_division_groups';

  IntColumn get id => integer()();
  IntColumn get markScaleGroupsId => integer()();
  TextColumn get name => text()();
  IntColumn get type => integer()();
  IntColumn get public => integer()();
  RealColumn get rangeMin => real().nullable()();
  RealColumn get rangeMax => real().nullable()();
  RealColumn get precision => real().nullable()();
  IntColumn get addByUsersId => integer().nullable()();
  IntColumn get markDivisionGroupEduId => integer().nullable()();
  RealColumn get rangeMaxToDisplay => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class MarkGroupGroupsTable extends Table {
  @override
  String get tableName => 'mark_group_groups';

  IntColumn get id => integer()();
  IntColumn get markDivisionGroupsId => integer().nullable()();
  TextColumn get name => text()();
  IntColumn get parentId => integer().nullable()();
  IntColumn get isPattern => integer()();
  IntColumn get position => integer()();
  IntColumn get weight => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class MarkGroupIssues extends Table {
  IntColumn get id => integer()();
  IntColumn get markGroupsId => integer()();
  IntColumn get issuesId => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class Attendances extends Table {
  IntColumn get id => integer()();
  IntColumn get eventsId => integer()();
  IntColumn get studentsId => integer()();
  IntColumn get typesId => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class AttendanceTypes extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get abbr => text()();
  TextColumn get style => text().nullable()();
  TextColumn get countAs => text()();
  TextColumn get type => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Messages extends Table {
  IntColumn get id => integer()();
  DateTimeColumn get sendTime => dateTime()();
  IntColumn get senderUsersId => integer()();
  IntColumn get recipientUsersId => integer()();
  TextColumn get title => text()();
  TextColumn get content => text()();
  DateTimeColumn get readTime => dateTime().nullable()();
  IntColumn get hide => integer()();
  TextColumn get files => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class UserReprimands extends Table {
  IntColumn get id => integer()();
  IntColumn get studentsId => integer()();
  IntColumn get teachersId => integer()();
  IntColumn get kindsId => integer()();
  DateTimeColumn get getDate => dateTime()();
  TextColumn get content => text()();
  DateTimeColumn get addTime => dateTime().nullable()();
  IntColumn get status => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class StudentGroupsTable extends Table {
  @override
  String get tableName => 'student_groups';

  IntColumn get id => integer()();
  IntColumn get studentsId => integer()();
  IntColumn get groupsId => integer()();
  IntColumn get number => integer()();
  DateTimeColumn get strikeOffTime => dateTime().nullable()();
  TextColumn get strikeOffReason => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class GroupEducators extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get groupsId => integer()();
  IntColumn get teachersEducatorId => integer()();
}

class GroupTermsTable extends Table {
  @override
  String get tableName => 'group_terms';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get groupsId => integer()();
  IntColumn get termsId => integer()();
}

class PermissionGroupsTable extends Table {
  @override
  String get tableName => 'permission_groups';

  IntColumn get id => integer()();
  IntColumn get permissionGroupsId => integer()();
  IntColumn get parentId => integer().nullable()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get additionalDescription => text().nullable()();
  TextColumn get image => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Permissions extends Table {
  IntColumn get id => integer()();
  IntColumn get permissionGroupsId => integer()();
  IntColumn get usersId => integer()();
  IntColumn get eduId => integer().nullable()();
  IntColumn get quantitativeLimit => integer().nullable()();
  DateTimeColumn get grantTime => dateTime().nullable()();
  DateTimeColumn get expireTime => dateTime().nullable()();
  IntColumn get source => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class TranslationCacheEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sourceHash => text()();
  TextColumn get targetLang => text()();
  TextColumn get translatedText => text()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

class CustomEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get accountId => integer().references(Accounts, #id)();
  TextColumn get title => text()();
  TextColumn get place => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get startTime => text()();
  TextColumn get endTime => text()();
  IntColumn get colorIndex => integer().withDefault(const Constant(0))();
  IntColumn get recurrenceType => integer().withDefault(const Constant(0))();
  DateTimeColumn get recurrenceStartDate => dateTime().nullable()();
  DateTimeColumn get recurrenceEndDate => dateTime().nullable()();
  IntColumn get recurrenceWeekdays => integer().nullable()();
}

class CustomEventOccurrences extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get customEventId => integer().references(CustomEvents, #id)();
  DateTimeColumn get date => dateTime()();
}

@DriftDatabase(
  tables: [
    Accounts,
    SyncMetadata,
    Students,
    Teachers,
    Subjects,
    Groups,
    Terms,
    Rooms,
    Events,
    EventTypes,
    EventTypeTeachers,
    EventTypeGroups,
    EventTypeTerms,
    EventSubjects,
    EventIssues,
    EventEvents,
    EventTypeSchedules,
    LessonGroups,
    Lessons,
    Marks,
    MarkGroupsTable,
    MarkKinds,
    MarkScaleGroupsTable,
    MarkScales,
    MarkDivisionGroupsTable,
    MarkGroupGroupsTable,
    MarkGroupIssues,
    Attendances,
    AttendanceTypes,
    Messages,
    UserReprimands,
    StudentGroupsTable,
    GroupEducators,
    GroupTermsTable,
    PermissionGroupsTable,
    Permissions,
    TranslationCacheEntries,
    CustomEvents,
    CustomEventOccurrences,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(translationCacheEntries);
          }
          if (from < 3) {
            await m.createTable(customEvents);
            await m.createTable(customEventOccurrences);
          }
        },
      );
}
