import 'package:bsharp/domain/date_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseFlexibleDate', () {
    test('parses an ISO date string', () {
      expect(parseFlexibleDate('2026-02-27'), DateTime(2026, 2, 27));
    });

    test('parses a dd.MM.yyyy date string', () {
      expect(parseFlexibleDate('27.02.2026'), DateTime(2026, 2, 27));
    });

    test('falls back to the sentinel date for a malformed string', () {
      expect(parseFlexibleDate('not a date'), DateTime(2000));
    });

    test('falls back to the sentinel date for an empty string', () {
      expect(parseFlexibleDate(''), DateTime(2000));
    });
  });
}
