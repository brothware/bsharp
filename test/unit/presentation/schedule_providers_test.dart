import 'package:bsharp/domain/entities/event.dart';
import 'package:bsharp/domain/entities/room.dart';
import 'package:bsharp/domain/entities/subject.dart';
import 'package:bsharp/domain/entities/teacher.dart';
import 'package:bsharp/domain/schedule_utils.dart';
import 'package:bsharp/presentation/grades/providers/grades_providers.dart';
import 'package:bsharp/presentation/schedule/providers/schedule_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Event event({
    int id = 1,
    DateTime? date,
    int number = 1,
    String startTime = '08:00:00',
    String endTime = '08:45:00',
    int eventTypesId = 10,
    int status = 1,
    int substitution = 0,
    int? roomsId,
  }) {
    return Event(
      id: id,
      date: date ?? DateTime(2026, 2, 27),
      number: number,
      startTime: startTime,
      endTime: endTime,
      eventTypesId: eventTypesId,
      status: status,
      substitution: substitution,
      roomsId: roomsId,
      type: 0,
      attr: 0,
      locked: 0,
    );
  }

  group('eventsForDateProvider', () {
    test('filters events by date and sorts by number', () {
      final container = ProviderContainer(
        overrides: [
          eventsProvider.overrideWith(
            (ref) => [
              event(number: 3, date: DateTime(2026, 2, 27)),
              event(id: 2, date: DateTime(2026, 2, 27)),
              event(id: 3, number: 2, date: DateTime(2026, 2, 28)),
            ],
          ),
        ],
      );

      final result = container.read(
        eventsForDateProvider(DateTime(2026, 2, 27)),
      );
      expect(result.length, 2);
      expect(result[0].number, 1);
      expect(result[1].number, 3);
    });

    test('returns empty for date with no events', () {
      final container = ProviderContainer(
        overrides: [
          eventsProvider.overrideWith(
            (ref) => [event(date: DateTime(2026, 2, 27))],
          ),
        ],
      );

      final result = container.read(eventsForDateProvider(DateTime(2026, 3)));
      expect(result, isEmpty);
    });
  });

  group('scheduleEntriesForDateProvider', () {
    test('resolves subject, teacher, and room names', () {
      final container = ProviderContainer(
        overrides: [
          eventsProvider.overrideWith(
            (ref) => [event(roomsId: 100, date: DateTime(2026, 2, 27))],
          ),
          eventTypesProvider.overrideWith(
            (ref) => [
              const EventType(
                id: 10,
                subjectsId: 200,
                teachingLevel: 0,
                substitution: 0,
              ),
            ],
          ),
          eventTypeTeachersProvider.overrideWith(
            (ref) => [
              const EventTypeTeacher(id: 1, teachersId: 300, eventTypesId: 10),
            ],
          ),
          subjectsProvider.overrideWith(
            (ref) => [
              const Subject(
                id: 200,
                subjectsEduId: 1,
                name: 'Math',
                abbr: 'MAT',
              ),
            ],
          ),
          teachersProvider.overrideWith(
            (ref) => [
              const Teacher(
                id: 300,
                login: 'jkowalski',
                usersEduId: 1,
                name: 'Jan',
                surname: 'Kowalski',
                userType: 1,
              ),
            ],
          ),
          roomsProvider.overrideWith(
            (ref) => [const Room(id: 100, name: '201')],
          ),
          eventSubjectsProvider.overrideWith((ref) => []),
        ],
      );

      final entries = container.read(
        scheduleEntriesForDateProvider(DateTime(2026, 2, 27)),
      );
      expect(entries.length, 1);
      expect(entries.first.subjectName, 'Math');
      expect(entries.first.teacherName, 'Jan Kowalski');
      expect(entries.first.roomName, '201');
    });

    test('detects cancelled status', () {
      final container = ProviderContainer(
        overrides: [
          eventsProvider.overrideWith(
            (ref) => [event(status: 2, date: DateTime(2026, 2, 27))],
          ),
          eventTypesProvider.overrideWith((ref) => []),
          eventTypeTeachersProvider.overrideWith((ref) => []),
          subjectsProvider.overrideWith((ref) => []),
          teachersProvider.overrideWith((ref) => []),
          roomsProvider.overrideWith((ref) => []),
          eventSubjectsProvider.overrideWith((ref) => []),
        ],
      );

      final entries = container.read(
        scheduleEntriesForDateProvider(DateTime(2026, 2, 27)),
      );
      expect(entries.first.changeType, ScheduleChangeType.cancelled);
    });

    test('detects substitution', () {
      final container = ProviderContainer(
        overrides: [
          eventsProvider.overrideWith(
            (ref) => [event(substitution: 1, date: DateTime(2026, 2, 27))],
          ),
          eventTypesProvider.overrideWith((ref) => []),
          eventTypeTeachersProvider.overrideWith((ref) => []),
          subjectsProvider.overrideWith((ref) => []),
          teachersProvider.overrideWith((ref) => []),
          roomsProvider.overrideWith((ref) => []),
          eventSubjectsProvider.overrideWith((ref) => []),
        ],
      );

      final entries = container.read(
        scheduleEntriesForDateProvider(DateTime(2026, 2, 27)),
      );
      expect(entries.first.changeType, ScheduleChangeType.substitution);
    });

    test('resolves event topic', () {
      final container = ProviderContainer(
        overrides: [
          eventsProvider.overrideWith(
            (ref) => [event(id: 42, date: DateTime(2026, 2, 27))],
          ),
          eventTypesProvider.overrideWith((ref) => []),
          eventTypeTeachersProvider.overrideWith((ref) => []),
          subjectsProvider.overrideWith((ref) => []),
          teachersProvider.overrideWith((ref) => []),
          roomsProvider.overrideWith((ref) => []),
          eventSubjectsProvider.overrideWith(
            (ref) => [
              const EventSubject(
                id: 1,
                eventsId: 42,
                content: 'Quadratic equations',
              ),
            ],
          ),
        ],
      );

      final entries = container.read(
        scheduleEntriesForDateProvider(DateTime(2026, 2, 27)),
      );
      expect(entries.first.topic, 'Quadratic equations');
    });
  });

  group('weekEntriesProvider', () {
    test('returns map with 5 weekdays', () {
      final container = ProviderContainer(
        overrides: [
          selectedDateProvider.overrideWith((ref) => DateTime(2026, 2, 27)),
          eventsProvider.overrideWith((ref) => []),
          eventTypesProvider.overrideWith((ref) => []),
          eventTypeTeachersProvider.overrideWith((ref) => []),
          subjectsProvider.overrideWith((ref) => []),
          teachersProvider.overrideWith((ref) => []),
          roomsProvider.overrideWith((ref) => []),
          eventSubjectsProvider.overrideWith((ref) => []),
        ],
      );

      final weekMap = container.read(weekEntriesProvider);
      expect(weekMap.length, 5);
    });
  });

  group('selectedWeekStartProvider', () {
    test('derives Monday from selected date', () {
      final container = ProviderContainer(
        overrides: [
          selectedDateProvider.overrideWith((ref) => DateTime(2026, 2, 27)),
        ],
      );

      final monday = container.read(selectedWeekStartProvider);
      expect(monday.weekday, DateTime.monday);
      expect(monday, DateTime(2026, 2, 23));
    });
  });
}
