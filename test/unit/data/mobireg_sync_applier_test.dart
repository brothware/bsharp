import 'package:bsharp/data/providers/mobireg/mobireg_sync_applier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('portal parsing normalises subject names', () {
    test('parseTests keeps the provider casing while renaming', () {
      final tests = parseTests([
        {
          'id': 1,
          'subjectName': 'przyroda',
          'date': '2026-09-17',
          'title': 'Obserwacja',
        },
        {
          'id': 2,
          'subjectName': 'kształcenie słuchu',
          'date': '2026-09-23',
        },
      ]);

      expect(tests.map((t) => t.subjectName), ['nature', 'ear training']);
    });

    test(
      'parseHomeworks turns the provider wording into the canonical name',
      () {
        final homeworks = parseHomeworks([
          {
            'id': 1,
            'subjectName': 'matematyka',
            'date': '2026-09-17',
            'dueDate': '2026-09-18',
            'content': 'Zadania 1-5',
          },
        ]);

        expect(homeworks.single.subjectName, 'mathematics');
      },
    );

    test(
      'parseChangelog turns the provider wording into the canonical name',
      () {
        final changelog = parseChangelog([
          {
            'type': 'mark',
            'dateTime': '2026-09-17 10:00',
            'subjectName': 'przyroda',
            'user': 'Joanna Komórek',
            'newName': '5',
            'newAdditionalInfo': '',
            'action': 'add',
          },
        ]);

        expect(changelog.single.subjectName, 'nature');
      },
    );

    test('leaves an unknown subject name alone', () {
      final tests = parseTests([
        {'id': 1, 'subjectName': 'Próba chóru', 'date': '2026-09-17'},
      ]);

      expect(tests.single.subjectName, 'Próba chóru');
    });

    test('leaves a missing subject name empty', () {
      final tests = parseTests([
        {'id': 1, 'date': '2026-09-17'},
      ]);

      expect(tests.single.subjectName, '');
    });
  });
}
