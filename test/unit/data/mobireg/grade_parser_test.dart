import 'package:bsharp/data/providers/mobireg/parsers/grade_parser.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fixtures/mobireg/fixtures.dart';

void main() {
  group('gradeValueOf', () {
    final cases = <String, double?>{
      '5': 5,
      '4+': 4.5,
      '3-': 2.75,
      '6': 6,
      '+': null,
      '-': null,
      'nb': null,
      '': null,
    };
    for (final MapEntry(key: raw, value: numeric) in cases.entries) {
      test('reads "$raw" as $numeric', () {
        final value = gradeValueOf(raw);

        expect(value.display, raw);
        expect(value.numeric, numeric);
      });
    }
  });

  group('parseMarks', () {
    test('resolves subject, category, teacher and term for every grade', () {
      final parsed = parseMarks(loadMobiregFixture('marks_term4'), termId: 4);

      final grade = parsed.grades.firstWhere((g) => g.id == 13415);
      expect(grade.subjectName, 'nature');
      expect(grade.subjectId, 54);
      expect(grade.displayValue, '4+');
      expect(grade.effectiveValue, 4.5);
      expect(grade.countsToAverage, isTrue);
      expect(grade.teacherName, 'Joanna Nowak');
      expect(grade.comment, 'poprawa');
      expect(grade.description, 'dział 1');
      expect(grade.termId, 4);
      expect(grade.date, DateTime(2026, 10, 2));
    });

    test('keeps a plus mark visible but out of the average', () {
      final parsed = parseMarks(loadMobiregFixture('marks_term4'), termId: 4);

      final plus = parsed.grades.firstWhere((g) => g.id == 13414);
      expect(plus.displayValue, '+');
      expect(plus.effectiveValue, isNull);
      expect(plus.countsToAverage, isFalse);
    });

    test('collects the teachers the view names', () {
      final parsed = parseMarks(loadMobiregFixture('marks_term4'), termId: 4);

      expect(parsed.teachers.map((t) => t.id), unorderedEquals([4938, 4977]));
      expect(parsed.teachers.firstWhere((t) => t.id == 4938).surname, 'Nowak');
    });

    test('honours weight and count_to_avg when present', () {
      final parsed = parseMarks({
        'subjects': <Object>[],
        'grades': [
          {
            'id': 1,
            'subjectId': 1,
            'value': '5',
            'date': '2026-10-01',
            'weight': 3,
            'count_to_avg': 0,
          },
        ],
        'teachers': <Object>[],
      }, termId: 4);

      expect(parsed.grades.single.weight, 3);
      expect(parsed.grades.single.countsToAverage, isFalse);
    });

    test('an empty term yields no grades', () {
      final parsed = parseMarks(loadMobiregFixture('marks_empty'), termId: 7);

      expect(parsed.grades, isEmpty);
      expect(parsed.teachers, isEmpty);
    });

    test('a grade without an id is a FormatException', () {
      expect(
        () => parseMarks({
          'subjects': <Object>[],
          'grades': [
            {'subjectId': 1, 'value': '5', 'date': '2026-10-01'},
          ],
          'teachers': <String, Object>{},
        }, termId: 4),
        throwsFormatException,
      );
    });
  });
}
