import 'package:bsharp/data/data_sources/local/database.dart';
import 'package:bsharp/domain/custom_event_utils.dart';
import 'package:bsharp/domain/entities/custom_event.dart' as domain;
import 'package:drift/drift.dart';

part 'custom_event_dao.g.dart';

@DriftAccessor(tables: [CustomEvents, CustomEventOccurrences])
class CustomEventDao extends DatabaseAccessor<AppDatabase>
    with _$CustomEventDaoMixin {
  CustomEventDao(super.attachedDatabase);

  Future<List<domain.CustomEvent>> getAllForAccount(int accountId) async {
    final rows = await (select(
      customEvents,
    )..where((t) => t.accountId.equals(accountId))).get();
    return rows.map(_toEntity).toList();
  }

  Future<List<({int customEventId, DateTime date})>> getOccurrencesInRange(
    int accountId,
    DateTime start,
    DateTime end,
  ) async {
    final query =
        select(customEventOccurrences).join([
            innerJoin(
              customEvents,
              customEvents.id.equalsExp(customEventOccurrences.customEventId),
            ),
          ])
          ..where(customEvents.accountId.equals(accountId))
          ..where(
            customEventOccurrences.date.isBiggerOrEqualValue(
              DateTime(start.year, start.month, start.day),
            ),
          )
          ..where(
            customEventOccurrences.date.isSmallerOrEqualValue(
              DateTime(end.year, end.month, end.day),
            ),
          );

    final rows = await query.get();
    return rows.map((row) {
      final occ = row.readTable(customEventOccurrences);
      return (customEventId: occ.customEventId, date: occ.date);
    }).toList();
  }

  Future<int> insertEvent(domain.CustomEvent event) async {
    final id = await into(customEvents).insert(
      CustomEventsCompanion.insert(
        accountId: event.accountId,
        title: event.title,
        place: Value(event.place),
        description: Value(event.description),
        startTime: event.startTime,
        endTime: event.endTime,
        colorIndex: Value(event.colorIndex),
        recurrenceType: Value(event.recurrenceType.index),
        recurrenceStartDate: Value(event.recurrenceStartDate),
        recurrenceEndDate: Value(event.recurrenceEndDate),
        recurrenceWeekdays: Value(event.recurrenceWeekdays),
      ),
    );
    return id;
  }

  Future<void> updateEvent(domain.CustomEvent event) async {
    await (update(customEvents)..where((t) => t.id.equals(event.id))).write(
      CustomEventsCompanion(
        title: Value(event.title),
        place: Value(event.place),
        description: Value(event.description),
        startTime: Value(event.startTime),
        endTime: Value(event.endTime),
        colorIndex: Value(event.colorIndex),
        recurrenceType: Value(event.recurrenceType.index),
        recurrenceStartDate: Value(event.recurrenceStartDate),
        recurrenceEndDate: Value(event.recurrenceEndDate),
        recurrenceWeekdays: Value(event.recurrenceWeekdays),
      ),
    );
  }

  Future<void> deleteEvent(int eventId) async {
    await (delete(
      customEventOccurrences,
    )..where((t) => t.customEventId.equals(eventId))).go();
    await (delete(customEvents)..where((t) => t.id.equals(eventId))).go();
  }

  Future<void> replaceOccurrences(int eventId, List<DateTime> dates) async {
    await (delete(
      customEventOccurrences,
    )..where((t) => t.customEventId.equals(eventId))).go();
    for (final date in dates) {
      await into(customEventOccurrences).insert(
        CustomEventOccurrencesCompanion.insert(
          customEventId: eventId,
          date: DateTime(date.year, date.month, date.day),
        ),
      );
    }
  }

  Future<void> regenerateWeeklyOccurrences(int eventId) async {
    final row = await (select(
      customEvents,
    )..where((t) => t.id.equals(eventId))).getSingle();
    final entity = _toEntity(row);
    if (entity.recurrenceType != domain.RecurrenceType.weekly) return;
    final dates = generateOccurrences(entity);
    await replaceOccurrences(eventId, dates);
  }

  domain.CustomEvent _toEntity(CustomEvent row) => domain.CustomEvent(
    id: row.id,
    accountId: row.accountId,
    title: row.title,
    place: row.place,
    description: row.description,
    startTime: row.startTime,
    endTime: row.endTime,
    colorIndex: row.colorIndex,
    recurrenceType: domain.RecurrenceType.fromIndex(row.recurrenceType),
    recurrenceStartDate: row.recurrenceStartDate,
    recurrenceEndDate: row.recurrenceEndDate,
    recurrenceWeekdays: row.recurrenceWeekdays,
  );
}
