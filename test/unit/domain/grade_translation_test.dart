import 'package:flutter_test/flutter_test.dart';
import 'package:bsharp/domain/grade_utils.dart';

void main() {
  group('translateGradeName', () {
    test('translates standard formal grade names', () {
      expect(translateGradeName('Celujący'), isNotEmpty);
      expect(translateGradeName('Bardzo dobry'), isNotEmpty);
      expect(translateGradeName('Dobry'), isNotEmpty);
      expect(translateGradeName('Dostateczny'), isNotEmpty);
      expect(translateGradeName('Dopuszczający'), isNotEmpty);
      expect(translateGradeName('Niedostateczny'), isNotEmpty);
    });

    test('translates colloquial grade names', () {
      expect(translateGradeName('Szóstka'), isNotEmpty);
      expect(translateGradeName('Piątka z plusem'), isNotEmpty);
      expect(translateGradeName('Piątka'), isNotEmpty);
      expect(translateGradeName('Czwórka'), isNotEmpty);
      expect(translateGradeName('Trójka'), isNotEmpty);
      expect(translateGradeName('Dwójka'), isNotEmpty);
      expect(translateGradeName('Jedynka'), isNotEmpty);
    });

    test('is case-insensitive but matches produce same result', () {
      final lower = translateGradeName('celujący');
      final upper = translateGradeName('CELUJĄCY');
      final title = translateGradeName('Celujący');
      expect(lower, lower.toLowerCase());
      expect(upper, upper.toUpperCase());
      expect(title[0], title[0].toUpperCase());
    });

    test('preserves lowercase casing', () {
      final result = translateGradeName('dobry');
      expect(result, result.toLowerCase());
    });

    test('preserves uppercase casing', () {
      final result = translateGradeName('DOBRY');
      expect(result, result.toUpperCase());
    });

    test('preserves title casing', () {
      final result = translateGradeName('Dobry');
      expect(result[0], result[0].toUpperCase());
    });

    test('falls back to original for unknown names', () {
      expect(translateGradeName('Custom Grade'), 'Custom Grade');
      expect(translateGradeName('Inna ocena'), 'Inna ocena');
    });

    test('handles feminine forms', () {
      expect(
        translateGradeName('Nieklasyfikowana'),
        translateGradeName('Nieklasyfikowany'),
      );
      expect(
        translateGradeName('Zwolniona'),
        translateGradeName('Zwolniony'),
      );
    });
  });

  group('translateGradeCategory', () {
    test('translates common category names', () {
      expect(translateGradeCategory('Sprawdzian'), isNotEmpty);
      expect(translateGradeCategory('Kartkówka'), isNotEmpty);
      expect(translateGradeCategory('Odpowiedź ustna'), isNotEmpty);
      expect(translateGradeCategory('Praca domowa'), isNotEmpty);
      expect(translateGradeCategory('Aktywność'), isNotEmpty);
    });

    test('preserves lowercase casing', () {
      final result = translateGradeCategory('sprawdzian');
      expect(result, result.toLowerCase());
    });

    test('preserves uppercase casing', () {
      final result = translateGradeCategory('SPRAWDZIAN');
      expect(result, result.toUpperCase());
    });

    test('falls back to original for unknown categories', () {
      expect(translateGradeCategory('Custom Category'), 'Custom Category');
    });
  });
}
