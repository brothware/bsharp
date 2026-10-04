@TestOn('vm')
library;

import 'package:bsharp/data/data_sources/local/database.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'default/generated/schema.dart';
import 'default/generated/schema_v4.dart' as v4;

void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('migrating from v4 produces the v5 schema', () async {
    final connection = await verifier.startAt(4);
    final db = AppDatabase(connection);
    await verifier.migrateAndValidate(db, 5);
    await db.close();
  });

  test('migrating from v4 keeps user data, drops dismissed alerts', () async {
    const eventTitle = 'Dentist';
    const ignoredAttendanceId = 77;
    const translatedText = 'czesc';
    const accountId = 1;
    const customEventId = 1;
    const timestampSeconds = 1790000000;
    final schema = await verifier.schemaAt(4);
    final oldDb = v4.DatabaseAtV4(schema.newConnection());
    await oldDb.customStatement(
      'INSERT INTO custom_events (account_id, title, start_time, end_time) '
      "VALUES ($accountId, '$eventTitle', '10:00', '11:00')",
    );
    await oldDb.customStatement(
      'INSERT INTO custom_event_occurrences (custom_event_id, date) '
      'VALUES ($customEventId, $timestampSeconds)',
    );
    await oldDb.customStatement(
      'INSERT INTO ignored_attendances (attendance_id, ignored_at) '
      'VALUES ($ignoredAttendanceId, $timestampSeconds)',
    );
    await oldDb.customStatement(
      'INSERT INTO translation_cache_entries '
      '(source_hash, target_lang, translated_text) '
      "VALUES ('hash', 'pl', '$translatedText')",
    );
    await oldDb.close();

    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 5);

    final events = await db.select(db.customEvents).get();
    final occurrences = await db.select(db.customEventOccurrences).get();
    final ignored = await db.select(db.ignoredAttendances).get();
    final translations = await db.select(db.translationCacheEntries).get();
    expect(events.map((row) => row.title), [eventTitle]);
    expect(occurrences, hasLength(1));
    expect(ignored, isEmpty);
    expect(translations.map((row) => row.translatedText), [translatedText]);
    await db.close();
  });
}
