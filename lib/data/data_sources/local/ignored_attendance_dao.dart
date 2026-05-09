import 'package:bsharp/data/data_sources/local/database.dart';
import 'package:drift/drift.dart';

part 'ignored_attendance_dao.g.dart';

@DriftAccessor(tables: [IgnoredAttendances])
class IgnoredAttendanceDao extends DatabaseAccessor<AppDatabase>
    with _$IgnoredAttendanceDaoMixin {
  IgnoredAttendanceDao(super.attachedDatabase);

  Stream<Set<int>> watchIgnoredIds() {
    return select(ignoredAttendances).watch().map(
      (rows) => rows.map((r) => r.attendanceId).toSet(),
    );
  }

  Future<Set<int>> getIgnoredIds() async {
    final rows = await select(ignoredAttendances).get();
    return rows.map((r) => r.attendanceId).toSet();
  }

  Future<void> markIgnored(int attendanceId) async {
    await into(ignoredAttendances).insertOnConflictUpdate(
      IgnoredAttendancesCompanion(
        attendanceId: Value(attendanceId),
        ignoredAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markUnignored(int attendanceId) async {
    await (delete(
      ignoredAttendances,
    )..where((t) => t.attendanceId.equals(attendanceId))).go();
  }
}
