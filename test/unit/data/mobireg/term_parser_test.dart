import 'package:bsharp/data/providers/mobireg/parsers/term_parser.dart';
import 'package:bsharp/domain/entities/sync_action.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fixtures/mobireg/fixtures.dart';

void main() {
  group('parseTerms', () {
    test('marks the school year and keeps the semester parents', () {
      final terms = parseTerms(loadMobiregFixture('terms'));

      expect(terms.first.type, TermType.year);
      expect(terms.first.startDate, DateTime(2026, 9));
      expect(terms[1].type, TermType.semester);
      expect(terms[1].parentId, 1);
    });

    test('maps parentId 0 to no parent', () {
      expect(parseTerms(loadMobiregFixture('terms')).first.parentId, isNull);
    });

    test('a term without an id is a FormatException', () {
      expect(
        () => parseTerms([
          {
            'isYear': 0,
            'label': 'Semestr I',
            'parentId': 1,
            'dateFrom': '2026-09-01',
            'dateTo': '2027-01-31',
          },
        ]),
        throwsFormatException,
      );
    });
  });

  group('parseSubjects', () {
    test('normalises the subject names', () {
      final subjects = parseSubjects(loadMobiregFixture('subjects'));

      expect(subjects.map((s) => s.id), [123, 54, 384]);
      expect(subjects[1].name, 'nature');
      expect(subjects[1].abbr, 'nature');
    });

    test('a payload that is not a list is a FormatException', () {
      expect(() => parseSubjects({'id': 1}), throwsFormatException);
    });
  });
}
