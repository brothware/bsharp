import 'package:bsharp/data/services/mobireg_translations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeMobiregReceiverRole', () {
    test('maps the roles poczta answers to canonical English', () {
      expect(normalizeMobiregReceiverRole('nauczyciel'), 'teacher');
      expect(normalizeMobiregReceiverRole('dyrektor'), 'principal');
      expect(normalizeMobiregReceiverRole('pedagog'), 'school counsellor');
      expect(normalizeMobiregReceiverRole('psycholog'), 'psychologist');
      expect(normalizeMobiregReceiverRole('sekretariat'), 'secretary');
    });

    test('keeps the case the server used', () {
      expect(normalizeMobiregReceiverRole('Rodzic'), 'Parent');
      expect(normalizeMobiregReceiverRole(' Nauczyciel '), 'Teacher');
    });

    test('passes an unknown role through', () {
      expect(normalizeMobiregReceiverRole('admin'), 'admin');
    });
  });
}
