import 'package:bsharp/data/providers/mobireg/parsers/school_item_parser.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fixtures/mobireg/fixtures.dart';

const _praiseType = 1;
const _remarkType = 2;
const _reprimandKind = 1;

void main() {
  group('parseTestItems', () {
    test('keeps the date part of dateTime and normalises subjects', () {
      final tests = parseTestItems(loadMobiregFixture('tests'));

      expect(tests.first.date, '2026-10-12');
      expect(tests.first.subjectName, 'ear training');
      expect(tests.first.description, isNull);
      expect(tests.last.description, 'rozdziały 1-3');
    });

    test('a payload that is not an object is a FormatException', () {
      expect(() => parseTestItems(<Object>[]), throwsFormatException);
    });
  });

  group('parseReprimandItems', () {
    test('reads the app API field names', () {
      final reprimands = parseReprimandItems(loadMobiregFixture('reprimands'));

      expect(reprimands.single.date, '2026-10-01');
      expect(reprimands.single.teacherName, 'Agnieszka Nowak');
      expect(reprimands.single.content, 'Wzorowe zachowanie na koncercie');
    });

    test('maps a praise to the type the notes screen shows as praise', () {
      final reprimands = parseReprimandItems(loadMobiregFixture('reprimands'));

      expect(reprimands.single.type, _praiseType);
    });

    test('maps a reprimand to the type the notes screen shows as remark', () {
      final reprimands = parseReprimandItems({
        'items': [
          {
            'id': 1,
            'kind': _reprimandKind,
            'getDate': '2026-10-02',
            'content': 'Spóźnienie',
          },
        ],
      });

      expect(reprimands.single.type, _remarkType);
    });
  });

  group('parseAnnouncements', () {
    test('become bulletins with their read state', () {
      final bulletins = parseAnnouncements(loadMobiregFixture('announcements'));

      expect(bulletins.single.id, 12);
      expect(bulletins.single.isRead, isTrue);
      expect(bulletins.single.content, '<p>Szanowni Państwo</p>');
    });

    test('a missing data list is a FormatException', () {
      expect(() => parseAnnouncements({'count': 0}), throwsFormatException);
    });
  });
}
