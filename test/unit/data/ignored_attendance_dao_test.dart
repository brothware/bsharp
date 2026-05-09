@TestOn('vm')
library;

import 'package:bsharp/data/data_sources/local/database.dart';
import 'package:bsharp/data/data_sources/local/ignored_attendance_dao.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late IgnoredAttendanceDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = IgnoredAttendanceDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('starts empty', () async {
    expect(await dao.getIgnoredIds(), isEmpty);
  });

  test('markIgnored stores the id', () async {
    await dao.markIgnored(42);
    expect(await dao.getIgnoredIds(), {42});
  });

  test('markIgnored is idempotent', () async {
    await dao.markIgnored(42);
    await dao.markIgnored(42);
    expect(await dao.getIgnoredIds(), {42});
  });

  test('markUnignored removes the id', () async {
    await dao.markIgnored(42);
    await dao.markIgnored(99);
    await dao.markUnignored(42);
    expect(await dao.getIgnoredIds(), {99});
  });

  test('markUnignored on missing id is a no-op', () async {
    await dao.markUnignored(123);
    expect(await dao.getIgnoredIds(), isEmpty);
  });

  test('watchIgnoredIds emits the current set after each change', () async {
    final stream = dao.watchIgnoredIds();
    final emitted = <Set<int>>[];
    final sub = stream.listen(emitted.add);

    await dao.markIgnored(1);
    await dao.markIgnored(2);
    await dao.markUnignored(1);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await sub.cancel();

    expect(emitted.last, {2});
    expect(emitted, isNotEmpty);
  });
}
