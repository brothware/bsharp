import 'package:bsharp/data/data_sources/local/connection/custom_event_connection.dart';
import 'package:bsharp/data/data_sources/local/custom_event_dao.dart';
import 'package:bsharp/data/data_sources/local/database.dart'
    hide CustomEvent, CustomEventOccurrence;
import 'package:bsharp/domain/entities/custom_event.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'custom_event_providers.g.dart';

final _customEventDatabaseInitProvider = FutureProvider<AppDatabase?>((ref) {
  return createCustomEventDatabase();
});

@Riverpod(keepAlive: true)
CustomEventDao? customEventDao(Ref ref) {
  final db = ref.watch(_customEventDatabaseInitProvider).value;
  if (db == null) return null;
  return CustomEventDao(db);
}

@Riverpod(keepAlive: true)
class CustomEvents extends _$CustomEvents {
  @override
  List<CustomEvent> build() => [];
  List<CustomEvent> get value => state;
  set value(List<CustomEvent> v) => state = v;
}

@Riverpod(keepAlive: true)
class CustomEventOccurrences extends _$CustomEventOccurrences {
  @override
  List<({int customEventId, DateTime date})> build() => [];
  List<({int customEventId, DateTime date})> get value => state;
  set value(List<({int customEventId, DateTime date})> v) => state = v;
}

Future<void> loadCustomEvents(WidgetRef ref, int accountId) async {
  final dao = ref.read(customEventDaoProvider);
  if (dao == null) return;
  final events = await dao.getAllForAccount(accountId);
  ref.read(customEventsProvider.notifier).value = events;

  final now = DateTime.now();
  final start = now.subtract(const Duration(days: 180));
  final end = now.add(const Duration(days: 180));
  final occurrences = await dao.getOccurrencesInRange(accountId, start, end);
  ref.read(customEventOccurrencesProvider.notifier).value = occurrences;
}

Future<void> saveCustomEvent(
  WidgetRef ref,
  CustomEvent event,
  List<DateTime> occurrenceDates,
) async {
  final dao = ref.read(customEventDaoProvider);
  if (dao == null) return;
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
  if (dao == null) return;
  await dao.deleteEvent(eventId);
  await loadCustomEvents(ref, accountId);
}
