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
    test('translates standard English canonical names', () {
      expect(translateSubjectName('Mathematics'), isNotEmpty);
      expect(translateSubjectName('Polish'), isNotEmpty);
      expect(translateSubjectName('History'), isNotEmpty);
      expect(translateSubjectName('Biology'), isNotEmpty);
      expect(translateSubjectName('Physical education'), isNotEmpty);
    });

    test('is case-insensitive', () {
      final lower = translateSubjectName('mathematics');
      final upper = translateSubjectName('MATHEMATICS');
      final title = translateSubjectName('Mathematics');
      expect(lower.toLowerCase(), lower);
      expect(upper.toUpperCase(), upper);
      expect(title[0], title[0].toUpperCase());
    });

    test('preserves lowercase casing', () {
      final result = translateSubjectName('mathematics');
      expect(result, result.toLowerCase());
    });

    test('preserves uppercase casing', () {
      final result = translateSubjectName('MATHEMATICS');
      expect(result, result.toUpperCase());
    });

    test('falls back to original for unknown subjects', () {
      expect(translateSubjectName('Special activities'), 'Special activities');
    });

    test('translates music subjects', () {
      expect(translateSubjectName('Piano'), isNotEmpty);
      expect(translateSubjectName('Clarinet'), isNotEmpty);
      expect(translateSubjectName('Vocal'), isNotEmpty);
    });

    test('translates education subjects', () {
      expect(translateSubjectName('Art education'), isNotEmpty);
      expect(translateSubjectName('Mathematics education'), isNotEmpty);
      expect(translateSubjectName('Health education'), isNotEmpty);
    });

    test('translates ensemble names', () {
      expect(translateSubjectName('Chamber ensemble'), isNotEmpty);
      expect(translateSubjectName('Orchestra'), isNotEmpty);
      expect(translateSubjectName('Choir'), isNotEmpty);
    });

    test('translates exact-match extras', () {
      expect(translateSubjectName('Behaviour'), isNotEmpty);
      expect(translateSubjectName('After-school care'), isNotEmpty);
      expect(translateSubjectName('Business and management'), isNotEmpty);
      expect(translateSubjectName('History and the present'), isNotEmpty);
    });
  });

  group('translateTermName', () {
    test('translates semester names', () {
      final result = translateTermName('Semester I');
      expect(result, isNotEmpty);
    });

    test('splits year from label and translates', () {
      final result = translateTermName('School year 2025/2026');
      expect(result, contains('2025/2026'));
    });

    test('preserves year when label changes', () {
      final result1 = translateTermName('School year 2025/2026');
      final result2 = translateTermName('School year 2026/2027');
      expect(result1, contains('2025/2026'));
      expect(result2, contains('2026/2027'));
      expect(
        result1.replaceAll('2025/2026', ''),
        result2.replaceAll('2026/2027', ''),
      );
    });

    test('falls back to original for unknown terms', () {
      expect(translateTermName('Trial period'), 'Trial period');
    });
  });

  group('translateAttendanceAbbr', () {
    test('translates standard abbreviations', () {
      expect(translateAttendanceAbbr('P'), isNotEmpty);
      expect(translateAttendanceAbbr('A'), isNotEmpty);
      expect(translateAttendanceAbbr('L'), isNotEmpty);
    });

    test('preserves casing', () {
      final lower = translateAttendanceAbbr('p');
      final upper = translateAttendanceAbbr('P');
      expect(lower, lower.toLowerCase());
      expect(upper, upper.toUpperCase());
    });

    test('falls back to original for unknown abbreviations', () {
      expect(translateAttendanceAbbr('xx'), 'xx');
    });
  });

  group('translateAttendanceName', () {
    test('translates standard English names', () {
      expect(translateAttendanceName('Present'), isNotEmpty);
      expect(translateAttendanceName('Absent'), isNotEmpty);
      expect(translateAttendanceName('Late'), isNotEmpty);
    });

    test('preserves lowercase casing', () {
      final result = translateAttendanceName('present');
      expect(result, result.toLowerCase());
    });

    test('translates compound attendance names', () {
      expect(translateAttendanceName('Excused absence'), isNotEmpty);
      expect(translateAttendanceName('Unexcused late'), isNotEmpty);
      expect(translateAttendanceName('Music competition'), isNotEmpty);
    });

    test('falls back to original for unknown names', () {
      expect(translateAttendanceName('Other status'), 'Other status');
    });
  });

  group('translateReceiverRole', () {
    test('translates standard English roles', () {
      expect(translateReceiverRole('Teacher'), isNotEmpty);
      expect(translateReceiverRole('Homeroom teacher'), isNotEmpty);
      expect(translateReceiverRole('Principal'), isNotEmpty);
    });

    test('preserves casing', () {
      final lower = translateReceiverRole('teacher');
      final upper = translateReceiverRole('TEACHER');
      final title = translateReceiverRole('Teacher');
      expect(lower, lower.toLowerCase());
      expect(upper, upper.toUpperCase());
      expect(title[0], title[0].toUpperCase());
    });

    test('falls back to original for unknown roles', () {
      expect(translateReceiverRole('consultant'), 'consultant');
    });
  });

  group('translateGradeName', () {
    test('translates English grade names', () {
      expect(translateGradeName('Excellent'), isNotEmpty);
      expect(translateGradeName('Very good'), isNotEmpty);
      expect(translateGradeName('Good'), isNotEmpty);
      expect(translateGradeName('Satisfactory'), isNotEmpty);
      expect(translateGradeName('Unsatisfactory'), isNotEmpty);
    });

    test('preserves casing', () {
      final lower = translateGradeName('excellent');
      final upper = translateGradeName('EXCELLENT');
      expect(lower, lower.toLowerCase());
      expect(upper, upper.toUpperCase());
    });

    test('falls back to original for unknown names', () {
      expect(translateGradeName('Special'), 'Special');
    });
  });

  group('translateGradeCategory', () {
    test('translates English category names', () {
      expect(translateGradeCategory('Exam'), isNotEmpty);
      expect(translateGradeCategory('Quiz'), isNotEmpty);
      expect(translateGradeCategory('Homework'), isNotEmpty);
    });

    test('preserves casing', () {
      final lower = translateGradeCategory('exam');
      final upper = translateGradeCategory('EXAM');
      expect(lower, lower.toLowerCase());
      expect(upper, upper.toUpperCase());
    });

    test('falls back to original for unknown categories', () {
      expect(translateGradeCategory('Special test'), 'Special test');
    });
  });

  group('gradeDistribution', () {
    test('counts grades by rounded value', () {
      final dist = gradeDistribution([5.0, 5.0, 4.0, 3.5, null]);
      expect(dist['5'], 2);
      expect(dist['4'], 2);
      expect(dist.containsKey('3'), isFalse);
    });

    test('returns empty for no values', () {
      expect(gradeDistribution([]), isEmpty);
    });

    test('skips null values', () {
      expect(gradeDistribution([null, null]), isEmpty);
    });
  });
}
