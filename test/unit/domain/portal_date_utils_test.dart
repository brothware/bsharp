import 'package:bsharp/domain/portal_date_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parsePortalDate', () {
    test('parses an ISO date string', () {
      expect(parsePortalDate('2026-02-27'), DateTime(2026, 2, 27));
    });

    test('parses a dd.MM.yyyy date string', () {
      expect(parsePortalDate('27.02.2026'), DateTime(2026, 2, 27));
    });

    test('falls back to the sentinel date for a malformed string', () {
      expect(parsePortalDate('not a date'), DateTime(2000));
    });

    test('falls back to the sentinel date for an empty string', () {
      expect(parsePortalDate(''), DateTime(2000));
    });
  });
}
