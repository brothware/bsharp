import 'package:bsharp/data/services/mobireg_translations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeMobiregTermName', () {
    test('handles the adjective-first Polish forms the server returns', () {
      expect(normalizeMobiregTermName('Pierwszy semestr'), 'Semester I');
      expect(normalizeMobiregTermName('Drugi semestr'), 'Semester II');
      expect(normalizeMobiregTermName('Trzeci semestr'), 'Semester III');
      expect(normalizeMobiregTermName('Pierwszy trymestr'), 'Trimester I');
    });

    test('still handles the noun-first forms', () {
      expect(normalizeMobiregTermName('Semestr pierwszy'), 'Semester I');
      expect(normalizeMobiregTermName('I semestr'), 'Semester I');
    });

    test('keeps a trailing school year', () {
      expect(
        normalizeMobiregTermName('Pierwszy semestr 2025/2026'),
        'Semester I 2025/2026',
      );
    });
  });
}
