import 'package:drift/drift.dart';

part 'database.g.dart';

class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get school => text()();
  TextColumn get login => text()();
  TextColumn get passwordHash => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class TranslationCacheEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sourceHash => text()();
  TextColumn get targetLang => text()();
  TextColumn get translatedText => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
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

class IgnoredAttendances extends Table {
  IntColumn get attendanceId => integer()();
  DateTimeColumn get ignoredAt => dateTime()();

  @override
  Set<Column> get primaryKey => {attendanceId};
}

const _removedTableNames = [
  'sync_metadata',
  'students',
  'teachers',
  'subjects',
  'groups',
  'terms',
  'rooms',
  'events',
  'event_types',
  'event_type_teachers',
  'event_type_groups',
  'event_type_terms',
  'event_subjects',
  'event_issues',
  'event_events',
  'event_type_schedules',
  'lesson_groups',
  'lessons',
  'marks',
  'mark_groups',
  'mark_kinds',
  'mark_scale_groups',
  'mark_scales',
  'mark_division_groups',
  'mark_group_groups',
  'mark_group_issues',
  'attendances',
  'attendance_types',
  'messages',
  'user_reprimands',
  'student_groups',
  'group_educators',
  'group_terms',
  'permission_groups',
  'permissions',
];

@DriftDatabase(
  tables: [
    Accounts,
    TranslationCacheEntries,
    CustomEvents,
    CustomEventOccurrences,
    IgnoredAttendances,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 5;

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
      if (from < 4) {
        await m.createTable(ignoredAttendances);
      }
      if (from < 5) {
        for (final tableName in _removedTableNames) {
          await m.deleteTable(tableName);
        }
      }
    },
  );
}
