import 'dart:io';

import 'package:drift/drift.dart' hide Column;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:bsharp/data/data_sources/local/custom_event_dao.dart';
import 'package:bsharp/data/data_sources/local/database.dart' hide CustomEvent, CustomEventOccurrence;
import 'package:bsharp/domain/entities/custom_event.dart';

final _customEventDatabaseProvider = Provider<AppDatabase>((ref) {
  late final AppDatabase db;
  db = AppDatabase(LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'custom_events.db'));
    return NativeDatabase.createInBackground(file);
  }));
  ref.onDispose(db.close);
  return db;
});

final customEventDaoProvider = Provider<CustomEventDao>((ref) {
  final db = ref.watch(_customEventDatabaseProvider);
  return CustomEventDao(db);
});

final customEventsProvider =
    StateProvider<List<CustomEvent>>((ref) => []);

final customEventOccurrencesProvider =
    StateProvider<List<({int customEventId, DateTime date})>>((ref) => []);

Future<void> loadCustomEvents(WidgetRef ref, int accountId) async {
  final dao = ref.read(customEventDaoProvider);
  final events = await dao.getAllForAccount(accountId);
  ref.read(customEventsProvider.notifier).state = events;

  final now = DateTime.now();
  final start = now.subtract(const Duration(days: 180));
  final end = now.add(const Duration(days: 180));
  final occurrences = await dao.getOccurrencesInRange(accountId, start, end);
  ref.read(customEventOccurrencesProvider.notifier).state = occurrences;
}

Future<void> saveCustomEvent(
  WidgetRef ref,
  CustomEvent event,
  List<DateTime> occurrenceDates,
) async {
  final dao = ref.read(customEventDaoProvider);
  if (event.id == 0) {
    final id = await dao.insertEvent(event);
    if (event.recurrenceType == RecurrenceType.weekly) {
      await dao.regenerateWeeklyOccurrences(id);
    } else {
      await dao.replaceOccurrences(id, occurrenceDates);
    }
  } else {
    await dao.updateEvent(event);
    if (event.recurrenceType == RecurrenceType.weekly) {
      await dao.regenerateWeeklyOccurrences(event.id);
    } else {
      await dao.replaceOccurrences(event.id, occurrenceDates);
    }
  }
  await loadCustomEvents(ref, event.accountId);
}

Future<void> deleteCustomEvent(
  WidgetRef ref,
  int eventId,
  int accountId,
) async {
  final dao = ref.read(customEventDaoProvider);
  await dao.deleteEvent(eventId);
  await loadCustomEvents(ref, accountId);
}
