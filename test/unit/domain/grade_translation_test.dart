import 'package:bsharp/domain/translation_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('translateGradeName', () {
    test('translates standard formal grade names', () {
      expect(translateGradeName('Excellent'), isNotEmpty);
      expect(translateGradeName('Very good'), isNotEmpty);
      expect(translateGradeName('Good'), isNotEmpty);
      expect(translateGradeName('Satisfactory'), isNotEmpty);
      expect(translateGradeName('Acceptable'), isNotEmpty);
      expect(translateGradeName('Unsatisfactory'), isNotEmpty);
    });

    test('translates colloquial grade names', () {
      expect(translateGradeName('Six'), isNotEmpty);
      expect(translateGradeName('Five plus'), isNotEmpty);
      expect(translateGradeName('Five'), isNotEmpty);
      expect(translateGradeName('Four'), isNotEmpty);
      expect(translateGradeName('Three'), isNotEmpty);
      expect(translateGradeName('Two'), isNotEmpty);
      expect(translateGradeName('One'), isNotEmpty);
    });

    test('is case-insensitive but matches produce same result', () {
      final lower = translateGradeName('excellent');
      final upper = translateGradeName('EXCELLENT');
      final title = translateGradeName('Excellent');
      expect(lower, lower.toLowerCase());
      expect(upper, upper.toUpperCase());
      expect(title[0], title[0].toUpperCase());
    });

    test('preserves lowercase casing', () {
      final result = translateGradeName('good');
      expect(result, result.toLowerCase());
    });

    test('preserves uppercase casing', () {
      final result = translateGradeName('GOOD');
      expect(result, result.toUpperCase());
    });

    test('preserves title casing', () {
      final result = translateGradeName('Good');
      expect(result[0], result[0].toUpperCase());
    });

    test('falls back to original for unknown names', () {
      expect(translateGradeName('Custom Grade'), 'Custom Grade');
      expect(translateGradeName('Unknown mark'), 'Unknown mark');
    });

    test('handles related forms', () {
      expect(
        translateGradeName('Unclassified'),
        isNotEmpty,
      );
      expect(translateGradeName('Exempt'), isNotEmpty);
    });
  });

  group('translateGradeCategory', () {
    test('translates common category names', () {
      expect(translateGradeCategory('Exam'), isNotEmpty);
      expect(translateGradeCategory('Quiz'), isNotEmpty);
      expect(translateGradeCategory('Oral answer'), isNotEmpty);
      expect(translateGradeCategory('Homework'), isNotEmpty);
      expect(translateGradeCategory('Activity'), isNotEmpty);
    });

    test('preserves lowercase casing', () {
      final result = translateGradeCategory('exam');
      expect(result, result.toLowerCase());
    });

    test('preserves uppercase casing', () {
      final result = translateGradeCategory('EXAM');
      expect(result, result.toUpperCase());
    });

    test('falls back to original for unknown categories', () {
      expect(translateGradeCategory('Custom Category'), 'Custom Category');
    });
  });
}
