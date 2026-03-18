import 'package:bsharp/domain/entities/resolved_event.dart';
import 'package:bsharp/domain/schedule_utils.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:bsharp/presentation/schedule/providers/schedule_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  ResolvedEvent resolved({
    int id = 1,
    DateTime? date,
    int number = 1,
    String startTime = '08:00:00',
    String endTime = '08:45:00',
    String? subjectName,
    String? teacherName,
    String? roomName,
    String? topic,
    int? subjectId,
    bool isCancelled = false,
    bool isSubstitution = false,
    bool isLocked = false,
    String? originalSubjectName,
    String? originalTeacherName,
    List<int> replacedLessonNumbers = const [],
    bool isReplaced = false,
    String? eventName,
  }) {
    return ResolvedEvent(
      id: id,
      date: date ?? DateTime(2026, 2, 27),
      number: number,
      startTime: startTime,
      endTime: endTime,
      subjectName: subjectName,
      teacherName: teacherName,
      roomName: roomName,
      topic: topic,
      subjectId: subjectId,
      isCancelled: isCancelled,
      isSubstitution: isSubstitution,
      isLocked: isLocked,
      originalSubjectName: originalSubjectName,
      originalTeacherName: originalTeacherName,
      replacedLessonNumbers: replacedLessonNumbers,
      isReplaced: isReplaced,
      eventName: eventName,
    );
  }

  group('scheduleEntriesForDateProvider', () {
    test('filters events by date and sorts by number', () {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          resolvedEventsProvider.overrideWithBuild(
            (ref, _) => [
              resolved(number: 3, date: DateTime(2026, 2, 27)),
              resolved(id: 2, date: DateTime(2026, 2, 27)),
              resolved(id: 3, number: 2, date: DateTime(2026, 2, 28)),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(
        scheduleEntriesForDateProvider(DateTime(2026, 2, 27)),
      );
      expect(result.length, 2);
      expect(result[0].number, 1);
      expect(result[1].number, 3);
    });

    test('returns empty for date with no events', () {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          resolvedEventsProvider.overrideWithBuild(
            (ref, _) => [resolved(date: DateTime(2026, 2, 27))],
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(
        scheduleEntriesForDateProvider(DateTime(2026, 3)),
      );
      expect(result, isEmpty);
    });

    test('resolves subject, teacher, and room names', () {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          resolvedEventsProvider.overrideWithBuild(
            (ref, _) => [
              resolved(
                date: DateTime(2026, 2, 27),
                subjectName: 'Math',
                teacherName: 'Jan Kowalski',
                roomName: '201',
              ),
            ],
          ),
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
          sharedPreferencesProvider.overrideWithValue(prefs),
          resolvedEventsProvider.overrideWithBuild(
            (ref, _) => [
              resolved(
                date: DateTime(2026, 2, 27),
                isCancelled: true,
              ),
            ],
          ),
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
          sharedPreferencesProvider.overrideWithValue(prefs),
          resolvedEventsProvider.overrideWithBuild(
            (ref, _) => [
              resolved(
                date: DateTime(2026, 2, 27),
                isSubstitution: true,
              ),
            ],
          ),
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
          sharedPreferencesProvider.overrideWithValue(prefs),
          resolvedEventsProvider.overrideWithBuild(
            (ref, _) => [
              resolved(
                id: 42,
                date: DateTime(2026, 2, 27),
                topic: 'Quadratic equations',
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
          sharedPreferencesProvider.overrideWithValue(prefs),
          resolvedEventsProvider.overrideWithBuild(
            (ref, _) => [
              resolved(
                id: 10,
                number: 5,
                date: DateTime(2026, 3, 5),
                isReplaced: true,
                isCancelled: true,
              ),
              resolved(
                id: 11,
                number: 6,
                date: DateTime(2026, 3, 5),
                isReplaced: true,
                isCancelled: true,
              ),
              resolved(
                id: 12,
                number: 7,
                date: DateTime(2026, 3, 5),
                isReplaced: true,
                isCancelled: true,
              ),
              resolved(
                id: 20,
                number: 0,
                date: DateTime(2026, 3, 5),
                isSubstitution: true,
                startTime: '10:40:00',
                endTime: '13:00:00',
                replacedLessonNumbers: [5, 6, 7],
              ),
            ],
          ),
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
          .where((e) => !e.isReplaced && e.isSubstitution)
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
            sharedPreferencesProvider.overrideWithValue(prefs),
            resolvedEventsProvider.overrideWithBuild(
              (ref, _) => [
                resolved(
                  id: 200,
                  number: 3,
                  date: DateTime(2026, 3, 10),
                  isSubstitution: true,
                  subjectName: 'Replacement Subject',
                  originalSubjectName: 'Original Subject',
                ),
              ],
            ),
          ],
        );
        addTearDown(container.dispose);

        final entries = container.read(
          scheduleEntriesForDateProvider(DateTime(2026, 3, 10)),
        );

        expect(entries.length, 1);
        expect(entries.first.id, 200);
        expect(entries.first.subjectName, 'Replacement Subject');
        expect(entries.first.changeType, ScheduleChangeType.substitution);
        expect(entries.first.originalSubjectName, 'Original Subject');
      },
    );

    test('empty eventName falls back to subject name', () {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          resolvedEventsProvider.overrideWithBuild(
            (ref, _) => [
              resolved(
                id: 10,
                number: 5,
                date: DateTime(2026, 3, 5),
                isReplaced: true,
                isCancelled: true,
              ),
              resolved(
                id: 20,
                date: DateTime(2026, 3, 5),
                number: 0,
                startTime: '10:40:00',
                endTime: '13:00:00',
                subjectName: 'Spektakl',
                eventName: '',
                replacedLessonNumbers: [5],
              ),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      final entries = container.read(
        scheduleEntriesForDateProvider(DateTime(2026, 3, 5)),
      );

      final replacement = entries.firstWhere((e) => e.id == 20);
      expect(replacement.subjectName, 'Spektakl');
    });

    test('sorts replaced originals before replacement', () {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          resolvedEventsProvider.overrideWithBuild(
            (ref, _) => [
              resolved(
                id: 10,
                number: 5,
                date: DateTime(2026, 3, 5),
                isReplaced: true,
                isCancelled: true,
              ),
              resolved(
                id: 11,
                number: 6,
                date: DateTime(2026, 3, 5),
                isReplaced: true,
                isCancelled: true,
              ),
              resolved(
                id: 20,
                number: 0,
                date: DateTime(2026, 3, 5),
                isSubstitution: true,
                replacedLessonNumbers: [5, 6],
              ),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      final entries = container.read(
        scheduleEntriesForDateProvider(DateTime(2026, 3, 5)),
      );

      final numbers = entries.map((e) => e.number).toList();
      expect(numbers, [5, 6, 0]);
    });
  });

  group('weekEntriesProvider', () {
    test('returns map with 5 weekdays', () {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          selectedDateProvider.overrideWithBuild(
            (ref, _) => DateTime(2026, 2, 27),
          ),
          resolvedEventsProvider.overrideWithBuild((ref, _) => []),
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
          sharedPreferencesProvider.overrideWithValue(prefs),
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
