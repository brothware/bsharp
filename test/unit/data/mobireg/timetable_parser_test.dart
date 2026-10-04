import 'package:bsharp/data/providers/mobireg/parsers/timetable_parser.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fixtures/mobireg/fixtures.dart';

void main() {
  group('parseTimetableEvents', () {
    final events = parseTimetableEvents(
      loadMobiregFixture('timetable_events'),
      subjectIdsByName: {'choir': 123},
    );

    test('reads date, times, room, teacher and topic', () {
      final choir = events.firstWhere((e) => e.id == 173);
      expect(choir.date, DateTime(2026, 9, 28));
      expect(choir.startTime, '14:25');
      expect(choir.endTime, '15:55');
      expect(choir.roomName, 'Aula');
      expect(choir.teacherName, 'Beata Nowak');
      expect(choir.topic, 'Swing Song');
      expect(choir.subjectId, 123);
      expect(choir.isLocked, isTrue);
      expect(choir.number, 0);
    });

    test('links a cancelled lesson to the lesson that replaced it', () {
      final cancelled = events.firstWhere((e) => e.id == 10994);
      expect(cancelled.isCancelled, isTrue);
      expect(cancelled.isReplaced, isTrue);
      expect(cancelled.replacedByEventId, 150190);
    });

    test('keeps what a substitution replaced', () {
      final substitute = events.firstWhere((e) => e.id == 150190);
      expect(substitute.isSubstitution, isTrue);
      expect(substitute.originalTeacherName, 'Teresa Nowak');
      expect(substitute.originalSubjectName, 'polish');
    });

    test('only substitution 1 marks a substitution', () {
      Map<String, dynamic> lesson(int id, Object? substitution) => {
        'id': id,
        'dateTimeFrom': '2026-09-28T08:00:00+02:00',
        'dateTimeTo': '2026-09-28T08:45:00+02:00',
        'subjectName': 'Chór',
        'teachers': <String>[],
        'substitution': ?substitution,
      };

      final parsed = parseTimetableEvents([
        lesson(1, null),
        lesson(2, false),
        lesson(3, 0),
        lesson(4, 1),
      ], subjectIdsByName: {});

      expect(parsed.map((event) => event.isSubstitution), [
        false,
        false,
        false,
        true,
      ]);
    });

    test('a missing dateTimeFrom is a FormatException', () {
      expect(
        () => parseTimetableEvents(
          [
            {'id': 1, 'subjectName': 'x', 'teachers': <String>[]},
          ],
          subjectIdsByName: {},
        ),
        throwsFormatException,
      );
    });
  });
}
