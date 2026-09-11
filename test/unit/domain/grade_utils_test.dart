import 'package:bsharp/core/constants/semantic_color.dart';
import 'package:bsharp/core/constants/semantic_palette.dart';
import 'package:bsharp/domain/entities/resolved_grade.dart';
import 'package:bsharp/domain/grade_utils.dart';
import 'package:bsharp/domain/translation_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ResolvedGrade _resolved({
  double? effectiveValue,
  String displayValue = '?',
  bool countsToAverage = true,
  int weight = 1,
  int id = 1,
}) {
  return ResolvedGrade(
    id: id,
    subjectName: 'Math',
    categoryName: 'Exam',
    displayValue: displayValue,
    date: DateTime(2026, 2, 27),
    effectiveValue: effectiveValue,
    countsToAverage: countsToAverage,
    weight: weight,
  );
}

void main() {
  group('SubjectGrades.weightedAverage', () {
    test('returns null for empty grades', () {
      final sg = SubjectGrades(
        subjectName: 'Math',
        subjectId: 1,
        grades: [],
      );
      expect(sg.weightedAverage, isNull);
    });

    test('returns null when all grades do not count to average', () {
      final sg = SubjectGrades(
        subjectName: 'Math',
        subjectId: 1,
        grades: [_resolved(countsToAverage: false)],
      );
      expect(sg.weightedAverage, isNull);
    });

    test('returns null when all grades have weight 0', () {
      final sg = SubjectGrades(
        subjectName: 'Math',
        subjectId: 1,
        grades: [_resolved(effectiveValue: 5, weight: 0)],
      );
      expect(sg.weightedAverage, isNull);
    });

    test('calculates simple average for equal weights', () {
      final sg = SubjectGrades(
        subjectName: 'Math',
        subjectId: 1,
        grades: [
          _resolved(effectiveValue: 5),
          _resolved(id: 2, effectiveValue: 3),
        ],
      );
      expect(sg.weightedAverage, 4.0);
    });

    test('calculates weighted average correctly', () {
      final sg = SubjectGrades(
        subjectName: 'Math',
        subjectId: 1,
        grades: [
          _resolved(effectiveValue: 5, weight: 3),
          _resolved(id: 2, effectiveValue: 3),
        ],
      );
      expect(sg.weightedAverage, closeTo(4.5, 0.01));
    });

    test('ignores grades that do not count to average', () {
      final sg = SubjectGrades(
        subjectName: 'Math',
        subjectId: 1,
        grades: [
          _resolved(effectiveValue: 4),
          _resolved(id: 2, countsToAverage: false),
        ],
      );
      expect(sg.weightedAverage, 4.0);
    });

    test('ignores grades with zero weight', () {
      final sg = SubjectGrades(
        subjectName: 'Math',
        subjectId: 1,
        grades: [
          _resolved(effectiveValue: 4),
          _resolved(id: 2, effectiveValue: 2, weight: 0),
        ],
      );
      expect(sg.weightedAverage, 4.0);
    });
  });

  group('gradeColor', () {
    test('maps bands to the dark palette', () {
      const b = Brightness.dark;
      expect(
        gradeColor(6, brightness: b),
        SemanticPalette.dark[SemanticColor.gradeExcellent],
      );
      expect(
        gradeColor(5.5, brightness: b),
        SemanticPalette.dark[SemanticColor.gradeExcellent],
      );
      expect(
        gradeColor(5, brightness: b),
        SemanticPalette.dark[SemanticColor.gradeVeryGood],
      );
      expect(
        gradeColor(4.5, brightness: b),
        SemanticPalette.dark[SemanticColor.gradeVeryGood],
      );
      expect(
        gradeColor(4, brightness: b),
        SemanticPalette.dark[SemanticColor.gradeGood],
      );
      expect(
        gradeColor(3.5, brightness: b),
        SemanticPalette.dark[SemanticColor.gradeGood],
      );
      expect(
        gradeColor(3, brightness: b),
        SemanticPalette.dark[SemanticColor.gradeSatisfactory],
      );
      expect(
        gradeColor(2.5, brightness: b),
        SemanticPalette.dark[SemanticColor.gradeSatisfactory],
      );
      expect(
        gradeColor(2, brightness: b),
        SemanticPalette.dark[SemanticColor.gradeAcceptable],
      );
      expect(
        gradeColor(1.5, brightness: b),
        SemanticPalette.dark[SemanticColor.gradeAcceptable],
      );
      expect(
        gradeColor(1, brightness: b),
        SemanticPalette.dark[SemanticColor.gradeFailing],
      );
      expect(
        gradeColor(null, brightness: b),
        SemanticPalette.dark[SemanticColor.gradeSatisfactory],
      );
    });

    test('maps the same bands to the light palette', () {
      const b = Brightness.light;
      expect(
        gradeColor(6, brightness: b),
        SemanticPalette.light[SemanticColor.gradeExcellent],
      );
      expect(
        gradeColor(1, brightness: b),
        SemanticPalette.light[SemanticColor.gradeFailing],
      );
    });

    test('light and dark differ', () {
      expect(
        gradeColor(4, brightness: Brightness.light),
        isNot(gradeColor(4, brightness: Brightness.dark)),
      );
    });
  });

  group('formatAverage', () {
    test('returns dash for null', () {
      expect(formatAverage(null), '-');
    });

    test('formats to 2 decimal places', () {
      expect(formatAverage(4.5), '4.50');
      expect(formatAverage(3.333), '3.33');
      expect(formatAverage(5), '5.00');
    });
  });

  group('gradeDistribution', () {
    test('returns empty map for empty list', () {
      expect(gradeDistribution([]), isEmpty);
    });

    test('counts rounded effective values correctly', () {
      final dist = gradeDistribution([5.0, 5.0, 4.0, 3.0]);
      expect(dist['5'], 2);
      expect(dist['4'], 1);
      expect(dist['3'], 1);
    });

    test('ignores null effectiveValues', () {
      final dist = gradeDistribution([5.0, null]);
      expect(dist.length, 1);
      expect(dist['5'], 1);
    });
  });
}
