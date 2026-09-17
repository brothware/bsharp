import 'package:bsharp/app/providers/dashboard_providers.dart';
import 'package:bsharp/app/providers/schedule_providers.dart';
import 'package:bsharp/domain/entities/resolved_event.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
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
    required DateTime date,
    int id = 1,
    bool isCancelled = false,
    bool isReplaced = false,
    int number = 1,
    String startTime = '08:00:00',
    String endTime = '08:45:00',
    String? subjectName,
    String? eventName,
  }) {
    return ResolvedEvent(
      id: id,
      date: date,
      number: number,
      startTime: startTime,
      endTime: endTime,
      isCancelled: isCancelled,
      isReplaced: isReplaced,
      subjectName: subjectName,
      eventName: eventName,
    );
  }

  DateTime dayOffset(int days) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).add(Duration(days: days));
  }

  group('currentLessonProvider', () {
    DateTime today() {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day);
    }

    ProviderContainer containerAt(int hour, int minute, List<ResolvedEvent> e) {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          resolvedEventsProvider.overrideWithBuild((ref, _) => e),
          minuteTickProvider.overrideWithValue(
            DateTime(today().year, today().month, today().day, hour, minute),
          ),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    ResolvedEvent rehearsal() => resolved(
      id: 30,
      date: today(),
      number: 0,
      startTime: '10:40:00',
      endTime: '13:15:00',
      eventName: 'Próba',
    );

    ResolvedEvent maths({bool isCancelled = false}) => resolved(
      id: 31,
      date: today(),
      number: 4,
      startTime: '10:40:00',
      endTime: '11:25:00',
      subjectName: 'matematyka',
      isCancelled: isCancelled,
    );

    test('reports every lesson running at once', () {
      final lesson = containerAt(
        10,
        45,
        [rehearsal(), maths()],
      ).read(currentLessonProvider);

      expect(lesson.current.map((e) => e.id), [30, 31]);
      expect(lesson.next, isEmpty);
    });

    test('reports every lesson that starts next', () {
      final lesson = containerAt(
        9,
        0,
        [rehearsal(), maths()],
      ).read(currentLessonProvider);

      expect(lesson.next.map((e) => e.id), [30, 31]);
      expect(lesson.current, isEmpty);
    });

    test('groups only the lessons sharing the earliest start', () {
      final lesson = containerAt(9, 0, [
        rehearsal(),
        maths(),
        resolved(
          id: 32,
          date: today(),
          subjectName: 'przyroda',
        ),
        resolved(
          id: 33,
          date: today(),
          number: 5,
          startTime: '11:30:00',
          endTime: '12:15:00',
          subjectName: 'zpt',
        ),
      ]).read(currentLessonProvider);

      expect(lesson.next.map((e) => e.id), [30, 31]);
    });

    test('leaves out a lesson cancelled by the overlapping event', () {
      final lesson = containerAt(10, 45, [
        rehearsal(),
        maths(isCancelled: true),
      ]).read(currentLessonProvider);

      expect(lesson.current.map((e) => e.id), [30]);
    });

    test('leaves out a lesson replaced by the overlapping event', () {
      final lesson = containerAt(10, 45, [
        rehearsal(),
        resolved(
          id: 31,
          date: today(),
          number: 4,
          startTime: '10:40:00',
          endTime: '11:25:00',
          subjectName: 'matematyka',
          isReplaced: true,
        ),
      ]).read(currentLessonProvider);

      expect(lesson.current.map((e) => e.id), [30]);
    });

    test('an ordinary day still yields one entry per slot', () {
      final lesson = containerAt(9, 0, [
        resolved(
          id: 32,
          date: today(),
          startTime: '09:45:00',
          endTime: '10:30:00',
          subjectName: 'przyroda',
        ),
      ]).read(currentLessonProvider);

      expect(lesson.current, isEmpty);
      expect(lesson.next.single.id, 32);
      expect(lesson.allEnded, isFalse);
    });

    test('reports the day as over once the last lesson ends', () {
      final lesson = containerAt(
        14,
        0,
        [maths()],
      ).read(currentLessonProvider);

      expect(lesson.current, isEmpty);
      expect(lesson.next, isEmpty);
      expect(lesson.allEnded, isTrue);
    });
  });

  group('nextSchoolDayProvider', () {
    test('returns tomorrow when it has a non-cancelled lesson', () {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          resolvedEventsProvider.overrideWithBuild(
            (ref, _) => [resolved(date: dayOffset(1))],
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(nextSchoolDayProvider), dayOffset(1));
    });

    test('skips days with only cancelled lessons', () {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          resolvedEventsProvider.overrideWithBuild(
            (ref, _) => [
              resolved(date: dayOffset(1), isCancelled: true),
              resolved(id: 2, date: dayOffset(2)),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(nextSchoolDayProvider), dayOffset(2));
    });

    test('returns null when no future lessons exist', () {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          resolvedEventsProvider.overrideWithBuild((ref, _) => []),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(nextSchoolDayProvider), isNull);
    });
  });
}
