import 'package:bsharp/data/providers/mobireg/parsers/account_parser.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fixtures/mobireg/fixtures.dart';

void main() {
  group('parseAccount', () {
    final account = parseAccount(
      loadMobiregFixture('users') as Map<String, dynamic>,
    );

    test('lists the pupils as students', () {
      expect(account.students.single.id, 6339);
      expect(account.students.single.name, 'Maria');
      expect(account.students.single.surname, 'Kowalska');
    });

    test('takes the first schoolName line as the school name', () {
      expect(
        account.schoolName,
        'Ogólnokształcąca Szkoła Muzyczna I i II stopnia',
      );
    });

    test('keeps the mail sign-in data', () {
      expect(account.messagingUrl, 'https://poczta.mobireg.pl/sso');
      expect(account.messagesToken, 'bW9jay1tZXNzYWdlcy10b2tlbg==');
    });

    test('lists the modules the school enabled', () {
      expect(
        account.enabledModules,
        containsAll([
          'attendances',
          'reprimands',
          'timetable',
          'announcements',
        ]),
      );
    });

    test('an account without pupils is a FormatException', () {
      expect(() => parseAccount({'id': 1}), throwsFormatException);
    });
  });
}
