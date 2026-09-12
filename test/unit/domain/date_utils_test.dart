import 'package:bsharp/domain/date_utils.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('monthName', () {
    test('returns the localised name for month 1', () {
      expect(monthName(1), t.attendance.month.jan);
    });

    test('returns the localised name for month 12', () {
      expect(monthName(12), t.attendance.month.dec);
    });

    test('returns an empty string for an out of range month', () {
      expect(monthName(0), '');
      expect(monthName(13), '');
    });
  });
}
