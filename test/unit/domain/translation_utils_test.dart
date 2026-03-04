import 'package:bsharp/domain/translation_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('matchCase', () {
    test('preserves uppercase', () {
      expect(matchCase('HELLO', 'world'), 'WORLD');
    });

    test('preserves lowercase', () {
      expect(matchCase('hello', 'World'), 'world');
    });

    test('preserves title case', () {
      expect(matchCase('Hello', 'world'), 'World');
    });

    test('returns as-is for empty original', () {
      expect(matchCase('', 'World'), 'World');
    });

    test('returns as-is for mixed case original', () {
      expect(matchCase('hELLO', 'World'), 'World');
    });
  });

  group('translateSubjectName', () {
    test('translates standard subject names', () {
      expect(translateSubjectName('Matematyka'), isNotEmpty);
      expect(translateSubjectName('Język polski'), isNotEmpty);
      expect(translateSubjectName('Historia'), isNotEmpty);
      expect(translateSubjectName('Biologia'), isNotEmpty);
      expect(translateSubjectName('Wychowanie fizyczne'), isNotEmpty);
    });

    test('is case-insensitive', () {
      final lower = translateSubjectName('matematyka');
      final upper = translateSubjectName('MATEMATYKA');
      final title = translateSubjectName('Matematyka');
      expect(lower.toLowerCase(), lower);
      expect(upper.toUpperCase(), upper);
      expect(title[0], title[0].toUpperCase());
    });

    test('preserves lowercase casing', () {
      final result = translateSubjectName('matematyka');
      expect(result, result.toLowerCase());
    });

    test('preserves uppercase casing', () {
      final result = translateSubjectName('MATEMATYKA');
      expect(result, result.toUpperCase());
    });

    test('translates abbreviations', () {
      expect(
        translateSubjectName('WOS').toLowerCase(),
        translateSubjectName('Wiedza o społeczeństwie').toLowerCase(),
      );
      expect(
        translateSubjectName('WF').toLowerCase(),
        translateSubjectName('Wychowanie fizyczne').toLowerCase(),
      );
    });

    test('falls back to original for unknown subjects', () {
      expect(translateSubjectName('Zajęcia specjalne'), 'Zajęcia specjalne');
    });

    test('translates instrument prefix and preserves suffix', () {
      final result = translateSubjectName('Fortepian zajęcia indywidualne');
      expect(result, contains('zajęcia indywidualne'));
      expect(result, isNot(startsWith('Fortepian')));
    });

    test('translates instrument with dates in suffix', () {
      final result = translateSubjectName('Skrzypce klasa III 2025/2026');
      expect(result, contains('klasa III 2025/2026'));
      expect(result, isNot(startsWith('Skrzypce')));
    });

    test('preserves casing on prefix match', () {
      final lower = translateSubjectName('fortepian zajęcia');
      final upper = translateSubjectName('FORTEPIAN zajęcia');
      final title = translateSubjectName('Fortepian zajęcia');
      expect(lower, startsWith(lower.split(' ').first.toLowerCase()));
      expect(upper, startsWith(upper.split(' ').first.toUpperCase()));
      expect(title[0], title[0].toUpperCase());
    });

    test('translates bare instrument name', () {
      expect(translateSubjectName('Fortepian'), isNotEmpty);
      expect(translateSubjectName('Klarnet'), isNotEmpty);
      expect(translateSubjectName('Śpiew'), isNotEmpty);
    });

    test('prefers longer prefix match', () {
      final result = translateSubjectName('Gitara klasyczna klasa II');
      final gitaraOnly = translateSubjectName('Gitara klasa II');
      expect(result, isNot(gitaraOnly));
    });

    test('translates music school subjects', () {
      expect(translateSubjectName('Kształcenie słuchu'), isNotEmpty);
      expect(translateSubjectName('Zespół kameralny'), isNotEmpty);
      expect(translateSubjectName('Orkiestra'), isNotEmpty);
    });

    test('translates education subjects', () {
      expect(translateSubjectName('Edukacja artystyczna'), isNotEmpty);
      expect(translateSubjectName('Edukacja matematyczna'), isNotEmpty);
      expect(translateSubjectName('Edukacja obywatelska'), isNotEmpty);
      expect(translateSubjectName('Edukacja zdrowotna'), isNotEmpty);
    });

    test('translates abbreviated school-specific subjects', () {
      expect(translateSubjectName('Zaj. kor. - komp.'), isNotEmpty);
      expect(translateSubjectName('Zajęcia op. wych.'), isNotEmpty);
      expect(translateSubjectName('Edukacja społ.-przyr.'), isNotEmpty);
    });

    test('translates exact-match extras', () {
      expect(translateSubjectName('Zachowanie'), isNotEmpty);
      expect(translateSubjectName('Świetlica'), isNotEmpty);
      expect(translateSubjectName('Biznes i zarządzanie'), isNotEmpty);
      expect(translateSubjectName('Historia i teraźniejszość'), isNotEmpty);
    });

    test('translates prefix-match with abbreviated ensemble names', () {
      final result = translateSubjectName('Zespół inst. Marching Band I st.');
      expect(result, isNotEmpty);
      expect(result, isNot('Zespół inst. Marching Band I st.'));
    });

    test('translates compound prefix subjects', () {
      final result = translateSubjectName('Fortepian dodatkowy klasa V');
      expect(result, contains('klasa V'));
      expect(result, isNot(startsWith('Fortepian dodatkowy')));
    });
  });

  group('translateTermName', () {
    test('translates semester names', () {
      final result = translateTermName('I semestr');
      expect(result, isNotEmpty);
      expect(result, isNot('I semestr'));
    });

    test('splits year from label and translates', () {
      final result = translateTermName('Rok szkolny 2025/2026');
      expect(result, contains('2025/2026'));
      expect(result, isNot(startsWith('Rok szkolny')));
    });

    test('preserves year when label changes', () {
      final result1 = translateTermName('Rok szkolny 2025/2026');
      final result2 = translateTermName('Rok szkolny 2026/2027');
      expect(result1, contains('2025/2026'));
      expect(result2, contains('2026/2027'));
      expect(
        result1.replaceAll('2025/2026', ''),
        result2.replaceAll('2026/2027', ''),
      );
    });

    test('preserves casing on term translation', () {
      final lower = translateTermName('i semestr');
      final upper = translateTermName('I SEMESTR');
      expect(lower, lower.toLowerCase());
      expect(upper, upper.toUpperCase());
    });

    test('falls back to original for unknown terms', () {
      expect(translateTermName('Okres próbny'), 'Okres próbny');
    });
  });

  group('translateAttendanceAbbr', () {
    test('translates standard abbreviations', () {
      expect(translateAttendanceAbbr('ob'), isNotEmpty);
      expect(translateAttendanceAbbr('nb'), isNotEmpty);
      expect(translateAttendanceAbbr('sp'), isNotEmpty);
    });

    test('preserves casing', () {
      final lower = translateAttendanceAbbr('ob');
      final upper = translateAttendanceAbbr('OB');
      expect(lower, lower.toLowerCase());
      expect(upper, upper.toUpperCase());
    });

    test('falls back to original for unknown abbreviations', () {
      expect(translateAttendanceAbbr('xx'), 'xx');
    });
  });

  group('translateAttendanceName', () {
    test('translates standard names', () {
      expect(translateAttendanceName('Obecność'), isNotEmpty);
      expect(translateAttendanceName('Nieobecność'), isNotEmpty);
      expect(translateAttendanceName('Spóźnienie'), isNotEmpty);
    });

    test('preserves lowercase casing', () {
      final result = translateAttendanceName('obecność');
      expect(result, result.toLowerCase());
    });

    test('translates compound attendance names', () {
      expect(
        translateAttendanceName('Nieobecność usprawiedliwiona'),
        isNotEmpty,
      );
      expect(
        translateAttendanceName('Spóźnienie nieusprawiedliwione'),
        isNotEmpty,
      );
      expect(translateAttendanceName('Konkurs muzyczny'), isNotEmpty);
    });

    test('falls back to original for unknown names', () {
      expect(translateAttendanceName('Inny status'), 'Inny status');
    });
  });

  group('translateReceiverRole', () {
    test('translates standard roles', () {
      expect(translateReceiverRole('nauczyciel'), isNotEmpty);
      expect(translateReceiverRole('wychowawca'), isNotEmpty);
      expect(translateReceiverRole('dyrektor'), isNotEmpty);
    });

    test('preserves casing', () {
      final lower = translateReceiverRole('nauczyciel');
      final upper = translateReceiverRole('NAUCZYCIEL');
      final title = translateReceiverRole('Nauczyciel');
      expect(lower, lower.toLowerCase());
      expect(upper, upper.toUpperCase());
      expect(title[0], title[0].toUpperCase());
    });

    test('handles feminine forms', () {
      expect(
        translateReceiverRole('nauczycielka').toLowerCase(),
        translateReceiverRole('nauczyciel').toLowerCase(),
      );
      expect(
        translateReceiverRole('wychowawczyni').toLowerCase(),
        translateReceiverRole('wychowawca').toLowerCase(),
      );
    });

    test('falls back to original for unknown roles', () {
      expect(translateReceiverRole('konsultant'), 'konsultant');
    });
  });
}
