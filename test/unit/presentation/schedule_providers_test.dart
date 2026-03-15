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
    String? name,
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
      name: name,
      type: 0,
      attr: 0,
      locked: 0,
    );
  }

  group('eventsForDateProvider', () {
    test('filters events by date and sorts by number', () {
      final container = ProviderContainer(
        overrides: [
          eventsProvider.overrideWithBuild(
            (ref, _) => [
              event(number: 3, date: DateTime(2026, 2, 27)),
              event(id: 2, date: DateTime(2026, 2, 27)),
              event(id: 3, number: 2, date: DateTime(2026, 2, 28)),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

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
          eventsProvider.overrideWithBuild(
            (ref, _) => [event(date: DateTime(2026, 2, 27))],
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(eventsForDateProvider(DateTime(2026, 3)));
      expect(result, isEmpty);
    });
  });

  group('scheduleEntriesForDateProvider', () {
    test('resolves subject, teacher, and room names', () {
      final container = ProviderContainer(
        overrides: [
          eventsProvider.overrideWithBuild(
            (ref, _) => [event(roomsId: 100, date: DateTime(2026, 2, 27))],
          ),
          eventTypesProvider.overrideWithBuild(
            (ref, _) => [
              const EventType(
                id: 10,
                subjectsId: 200,
                teachingLevel: 0,
                substitution: 0,
              ),
            ],
          ),
          eventTypeTeachersProvider.overrideWithBuild(
            (ref, _) => [
              const EventTypeTeacher(id: 1, teachersId: 300, eventTypesId: 10),
            ],
          ),
          subjectsProvider.overrideWithBuild(
            (ref, _) => [
              const Subject(
                id: 200,
                subjectsEduId: 1,
                name: 'Math',
                abbr: 'MAT',
              ),
            ],
          ),
          teachersProvider.overrideWithBuild(
            (ref, _) => [
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
          roomsProvider.overrideWithBuild(
            (ref, _) => [const Room(id: 100, name: '201')],
          ),
          eventSubjectsProvider.overrideWithBuild((ref, _) => []),
        ],
      );
      addTearDown(container.dispose);

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
          eventsProvider.overrideWithBuild(
            (ref, _) => [event(status: 2, date: DateTime(2026, 2, 27))],
          ),
          eventTypesProvider.overrideWithBuild((ref, _) => []),
          eventTypeTeachersProvider.overrideWithBuild((ref, _) => []),
          subjectsProvider.overrideWithBuild((ref, _) => []),
          teachersProvider.overrideWithBuild((ref, _) => []),
          roomsProvider.overrideWithBuild((ref, _) => []),
          eventSubjectsProvider.overrideWithBuild((ref, _) => []),
        ],
      );
      addTearDown(container.dispose);

      final entries = container.read(
        scheduleEntriesForDateProvider(DateTime(2026, 2, 27)),
      );
      expect(entries.first.changeType, ScheduleChangeType.cancelled);
    });

    test('detects substitution', () {
      final container = ProviderContainer(
        overrides: [
          eventsProvider.overrideWithBuild(
            (ref, _) => [event(substitution: 2, date: DateTime(2026, 2, 27))],
          ),
          eventTypesProvider.overrideWithBuild((ref, _) => []),
          eventTypeTeachersProvider.overrideWithBuild((ref, _) => []),
          subjectsProvider.overrideWithBuild((ref, _) => []),
          teachersProvider.overrideWithBuild((ref, _) => []),
          roomsProvider.overrideWithBuild((ref, _) => []),
          eventSubjectsProvider.overrideWithBuild((ref, _) => []),
        ],
      );
      addTearDown(container.dispose);

      final entries = container.read(
        scheduleEntriesForDateProvider(DateTime(2026, 2, 27)),
      );
      expect(entries.first.changeType, ScheduleChangeType.substitution);
    });

    test('resolves event topic', () {
      final container = ProviderContainer(
        overrides: [
          eventsProvider.overrideWithBuild(
            (ref, _) => [event(id: 42, date: DateTime(2026, 2, 27))],
          ),
          eventTypesProvider.overrideWithBuild((ref, _) => []),
          eventTypeTeachersProvider.overrideWithBuild((ref, _) => []),
          subjectsProvider.overrideWithBuild((ref, _) => []),
          teachersProvider.overrideWithBuild((ref, _) => []),
          roomsProvider.overrideWithBuild((ref, _) => []),
          eventSubjectsProvider.overrideWithBuild(
            (ref, _) => [
              const EventSubject(
                id: 1,
                eventsId: 42,
                content: 'Quadratic equations',
              ),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      final entries = container.read(
        scheduleEntriesForDateProvider(DateTime(2026, 2, 27)),
      );
      expect(entries.first.topic, 'Quadratic equations');
    });

    test('marks replaced originals and enriches replacement entries', () {
      final container = ProviderContainer(
        overrides: [
          eventsProvider.overrideWithBuild(
            (ref, _) => [
              event(id: 10, number: 5, date: DateTime(2026, 3, 5)),
              event(id: 11, number: 6, date: DateTime(2026, 3, 5)),
              event(id: 12, number: 7, date: DateTime(2026, 3, 5)),
              event(
                id: 20,
                number: 0,
                date: DateTime(2026, 3, 5),
                substitution: 2,
                startTime: '10:40:00',
                endTime: '13:00:00',
              ),
            ],
          ),
          eventEventsProvider.overrideWithBuild(
            (ref, _) => [
              const EventEvent(id: 1, events1Id: 20, events2Id: 10),
              const EventEvent(id: 2, events1Id: 20, events2Id: 11),
              const EventEvent(id: 3, events1Id: 20, events2Id: 12),
            ],
          ),
          eventTypesProvider.overrideWithBuild((ref, _) => []),
          eventTypeTeachersProvider.overrideWithBuild((ref, _) => []),
          subjectsProvider.overrideWithBuild((ref, _) => []),
          teachersProvider.overrideWithBuild((ref, _) => []),
          roomsProvider.overrideWithBuild((ref, _) => []),
          eventSubjectsProvider.overrideWithBuild((ref, _) => []),
        ],
      );
      addTearDown(container.dispose);

      final entries = container.read(
        scheduleEntriesForDateProvider(DateTime(2026, 3, 5)),
      );

      expect(entries.length, 4);

      final replaced = entries.where((e) => e.isReplaced).toList();
      expect(replaced.length, 3);
      for (final r in replaced) {
        expect(r.changeType, ScheduleChangeType.cancelled);
        expect(r.displayLessonNumber, '-');
      }

      final replacement = entries
          .where((e) => !e.isReplaced && e.event.substitution == 2)
          .first;
      expect(replacement.replacedLessonNumbers, [5, 6, 7]);
      expect(replacement.displayLessonNumber, '5-7');
      expect(replacement.changeType, ScheduleChangeType.substitution);
    });

    test(
      'Type A: hides original and shows replacement with correct subject',
      () {
        final container = ProviderContainer(
          overrides: [
            eventsProvider.overrideWithBuild(
              (ref, _) => [
                event(
                  id: 100,
                  number: 3,
                  date: DateTime(2026, 3, 10),
                  substitution: 1,
                  status: 0,
                  eventTypesId: 10,
                ),
                event(
                  id: 200,
                  number: 3,
                  date: DateTime(2026, 3, 10),
                  substitution: 2,
                  status: 1,
                  eventTypesId: 20,
                  name: '<b>Original Subject</b> 8:00-8:45 sala 12',
                ),
              ],
            ),
            eventEventsProvider.overrideWithBuild(
              (ref, _) => [
                const EventEvent(id: 1, events1Id: 100, events2Id: 200),
              ],
            ),
            eventTypesProvider.overrideWithBuild(
              (ref, _) => [
                const EventType(
                  id: 10,
                  subjectsId: 300,
                  teachingLevel: 0,
                  substitution: 0,
                ),
                const EventType(
                  id: 20,
                  subjectsId: 400,
                  teachingLevel: 0,
                  substitution: 0,
                ),
              ],
            ),
            subjectsProvider.overrideWithBuild(
              (ref, _) => [
                const Subject(
                  id: 300,
                  subjectsEduId: 1,
                  name: 'Original Subject',
                  abbr: 'OS',
                ),
                const Subject(
                  id: 400,
                  subjectsEduId: 2,
                  name: 'Replacement Subject',
                  abbr: 'RS',
                ),
              ],
            ),
            eventTypeTeachersProvider.overrideWithBuild((ref, _) => []),
            teachersProvider.overrideWithBuild((ref, _) => []),
            roomsProvider.overrideWithBuild((ref, _) => []),
            eventSubjectsProvider.overrideWithBuild((ref, _) => []),
          ],
        );
        addTearDown(container.dispose);

        final entries = container.read(
          scheduleEntriesForDateProvider(DateTime(2026, 3, 10)),
        );

        expect(entries.length, 1);
        expect(entries.first.event.id, 200);
        expect(entries.first.subjectName, 'Replacement Subject');
        expect(entries.first.changeType, ScheduleChangeType.substitution);
        expect(entries.first.originalSubjectName, 'Original Subject');
      },
    );

    test('empty event.name falls back to subject name', () {
      final container = ProviderContainer(
        overrides: [
          eventsProvider.overrideWithBuild(
            (ref, _) => [
              event(id: 10, number: 5, date: DateTime(2026, 3, 5)),
              Event(
                id: 20,
                date: DateTime(2026, 3, 5),
                number: 0,
                startTime: '10:40:00',
                endTime: '13:00:00',
                eventTypesId: 20,
                status: 1,
                substitution: 0,
                type: 0,
                attr: 0,
                locked: 0,
                name: '',
              ),
            ],
          ),
          eventEventsProvider.overrideWithBuild(
            (ref, _) => [
              const EventEvent(id: 1, events1Id: 20, events2Id: 10),
            ],
          ),
          eventTypesProvider.overrideWithBuild(
            (ref, _) => [
              const EventType(
                id: 20,
                subjectsId: 400,
                teachingLevel: 0,
                substitution: 0,
              ),
            ],
          ),
          subjectsProvider.overrideWithBuild(
            (ref, _) => [
              const Subject(
                id: 400,
                subjectsEduId: 1,
                name: 'Spektakl',
                abbr: 'SP',
              ),
            ],
          ),
          eventTypeTeachersProvider.overrideWithBuild((ref, _) => []),
          teachersProvider.overrideWithBuild((ref, _) => []),
          roomsProvider.overrideWithBuild((ref, _) => []),
          eventSubjectsProvider.overrideWithBuild((ref, _) => []),
        ],
      );
      addTearDown(container.dispose);

      final entries = container.read(
        scheduleEntriesForDateProvider(DateTime(2026, 3, 5)),
      );

      final replacement = entries.firstWhere((e) => e.event.id == 20);
      expect(replacement.subjectName, 'Spektakl');
    });

    test('sorts replaced originals before replacement', () {
      final container = ProviderContainer(
        overrides: [
          eventsProvider.overrideWithBuild(
            (ref, _) => [
              event(id: 10, number: 5, date: DateTime(2026, 3, 5)),
              event(id: 11, number: 6, date: DateTime(2026, 3, 5)),
              event(
                id: 20,
                number: 0,
                date: DateTime(2026, 3, 5),
                substitution: 2,
              ),
            ],
          ),
          eventEventsProvider.overrideWithBuild(
            (ref, _) => [
              const EventEvent(id: 1, events1Id: 20, events2Id: 10),
              const EventEvent(id: 2, events1Id: 20, events2Id: 11),
            ],
          ),
          eventTypesProvider.overrideWithBuild((ref, _) => []),
          eventTypeTeachersProvider.overrideWithBuild((ref, _) => []),
          subjectsProvider.overrideWithBuild((ref, _) => []),
          teachersProvider.overrideWithBuild((ref, _) => []),
          roomsProvider.overrideWithBuild((ref, _) => []),
          eventSubjectsProvider.overrideWithBuild((ref, _) => []),
        ],
      );
      addTearDown(container.dispose);

      final entries = container.read(
        scheduleEntriesForDateProvider(DateTime(2026, 3, 5)),
      );

      final numbers = entries.map((e) => e.event.number).toList();
      expect(numbers, [5, 6, 0]);
    });
  });

  group('weekEntriesProvider', () {
    test('returns map with 5 weekdays', () {
      final container = ProviderContainer(
        overrides: [
          selectedDateProvider.overrideWithBuild(
            (ref, _) => DateTime(2026, 2, 27),
          ),
          eventsProvider.overrideWithBuild((ref, _) => []),
          eventTypesProvider.overrideWithBuild((ref, _) => []),
          eventTypeTeachersProvider.overrideWithBuild((ref, _) => []),
          subjectsProvider.overrideWithBuild((ref, _) => []),
          teachersProvider.overrideWithBuild((ref, _) => []),
          roomsProvider.overrideWithBuild((ref, _) => []),
          eventSubjectsProvider.overrideWithBuild((ref, _) => []),
        ],
      );
      addTearDown(container.dispose);

      final weekMap = container.read(weekEntriesProvider);
      expect(weekMap.length, 5);
    });
  });

  group('selectedWeekStartProvider', () {
    test('derives Monday from selected date', () {
      final container = ProviderContainer(
        overrides: [
          selectedDateProvider.overrideWithBuild(
            (ref, _) => DateTime(2026, 2, 27),
          ),
        ],
      );
      addTearDown(container.dispose);

      final monday = container.read(selectedWeekStartProvider);
      expect(monday.weekday, DateTime.monday);
      expect(monday, DateTime(2026, 2, 23));
    });
  });
}
