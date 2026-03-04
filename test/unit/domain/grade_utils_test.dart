import 'package:bsharp/core/constants/app_colors.dart';
import 'package:bsharp/domain/entities/mark.dart';
import 'package:bsharp/domain/grade_utils.dart';
import 'package:flutter_test/flutter_test.dart';

Mark _mark({
  int id = 1,
  int markGroupsId = 1,
  double? markValue,
  int weight = 1,
  int? markScalesId,
  DateTime? getDate,
}) {
  return Mark(
    id: id,
    markGroupsId: markGroupsId,
    pupilUsersId: 1,
    teacherUsersId: 1,
    markValue: markValue,
    markScalesId: markScalesId,
    weight: weight,
    getDate: getDate ?? DateTime(2026, 2, 27),
    modified: 0,
  );
}

ResolvedMark _resolved({
  double? effectiveValue,
  String displayValue = '?',
  bool countsToAverage = true,
  int weight = 1,
  int id = 1,
}) {
  return ResolvedMark(
    mark: _mark(id: id, weight: weight),
    displayValue: displayValue,
    effectiveValue: effectiveValue,
    countsToAverage: countsToAverage,
  );
}

void main() {
  group('resolveMark', () {
    test('uses scale abbreviation when mark has markScalesId', () {
      final scaleById = {
        118: const MarkScale(
          id: 118,
          markScaleGroupsId: 10,
          abbreviation: '4+',
          name: 'Four plus',
          markValue: 4.5,
          classified: 1,
          noCountToAverage: 0,
        ),
      };
      final groupById = {
        1: const MarkGroup(
          id: 1,
          isPattern: 0,
          markType: 1,
          visibility: 1,
          position: 0,
        ),
      };
      final mark = _mark(markScalesId: 118);
      final rm = resolveMark(
        mark: mark,
        scaleById: scaleById,
        groupById: groupById,
      );

      expect(rm.displayValue, '4+');
      expect(rm.effectiveValue, 4.5);
      expect(rm.countsToAverage, true);
    });

    test('uses scale with noCountToAverage', () {
      final scaleById = {
        43: const MarkScale(
          id: 43,
          markScaleGroupsId: 7,
          abbreviation: 'np',
          name: 'Unprepared',
          markValue: 0,
          classified: 1,
          noCountToAverage: 1,
        ),
      };
      final groupById = {
        1: const MarkGroup(
          id: 1,
          isPattern: 0,
          markType: 1,
          visibility: 1,
          position: 0,
        ),
      };
      final mark = _mark(markScalesId: 43);
      final rm = resolveMark(
        mark: mark,
        scaleById: scaleById,
        groupById: groupById,
      );

      expect(rm.displayValue, 'np');
      expect(rm.countsToAverage, false);
    });

    test('shows point-based format value/max for markType 2', () {
      final groupById = {
        10: const MarkGroup(
          id: 10,
          isPattern: 0,
          markType: 2,
          visibility: 1,
          position: 0,
          markValueRangeMin: 0,
          markValueRangeMax: 10,
        ),
      };
      final mark = _mark(markGroupsId: 10, markValue: 8);
      final rm = resolveMark(mark: mark, scaleById: {}, groupById: groupById);

      expect(rm.displayValue, '8/10');
      expect(rm.effectiveValue, 5.0);
      expect(rm.isPointBased, true);
      expect(rm.markMax, 10);
    });

    test(
      'normalizes point-based effectiveValue to 1-6 scale rounded to 0.5',
      () {
        final groupById = {
          10: const MarkGroup(
            id: 10,
            isPattern: 0,
            markType: 2,
            visibility: 1,
            position: 0,
            markValueRangeMin: 0,
            markValueRangeMax: 21,
          ),
        };

        final min = resolveMark(
          mark: _mark(markGroupsId: 10, markValue: 0),
          scaleById: {},
          groupById: groupById,
        );
        expect(min.effectiveValue, 1.0);

        final max = resolveMark(
          mark: _mark(markGroupsId: 10, markValue: 21),
          scaleById: {},
          groupById: groupById,
        );
        expect(max.effectiveValue, 6.0);

        final mid = resolveMark(
          mark: _mark(markGroupsId: 10, markValue: 16),
          scaleById: {},
          groupById: groupById,
        );
        expect(mid.effectiveValue, 5.0);

        final half = resolveMark(
          mark: _mark(markGroupsId: 10, markValue: 10),
          scaleById: {},
          groupById: groupById,
        );
        expect(half.effectiveValue, 3.5);
      },
    );

    test('normalizes with non-zero range min', () {
      final groupById = {
        10: const MarkGroup(
          id: 10,
          isPattern: 0,
          markType: 2,
          visibility: 1,
          position: 0,
          markValueRangeMin: 1,
          markValueRangeMax: 25,
        ),
      };

      final min = resolveMark(
        mark: _mark(markGroupsId: 10, markValue: 1),
        scaleById: {},
        groupById: groupById,
      );
      expect(min.effectiveValue, 1.0);

      final max = resolveMark(
        mark: _mark(markGroupsId: 10, markValue: 25),
        scaleById: {},
        groupById: groupById,
      );
      expect(max.effectiveValue, 6.0);
    });

    test('shows plain value for markType 1 without scale', () {
      final groupById = {
        1: const MarkGroup(
          id: 1,
          isPattern: 0,
          markType: 1,
          visibility: 1,
          position: 0,
        ),
      };
      final mark = _mark(markValue: 5);
      final rm = resolveMark(mark: mark, scaleById: {}, groupById: groupById);

      expect(rm.displayValue, '5');
      expect(rm.effectiveValue, 5);
      expect(rm.isPointBased, false);
    });

    test('shows ? for null markValue and no scale', () {
      final groupById = {
        1: const MarkGroup(
          id: 1,
          isPattern: 0,
          markType: 1,
          visibility: 1,
          position: 0,
        ),
      };
      final mark = _mark();
      final rm = resolveMark(mark: mark, scaleById: {}, groupById: groupById);

      expect(rm.displayValue, '?');
      expect(rm.effectiveValue, isNull);
      expect(rm.countsToAverage, false);
    });
  });

  group('SubjectGrades.weightedAverage', () {
    test('returns null for empty marks', () {
      final sg = SubjectGrades(
        subjectName: 'Math',
        subjectId: 1,
        resolvedMarks: [],
      );
      expect(sg.weightedAverage, isNull);
    });

    test('returns null when all marks do not count to average', () {
      final sg = SubjectGrades(
        subjectName: 'Math',
        subjectId: 1,
        resolvedMarks: [_resolved(countsToAverage: false)],
      );
      expect(sg.weightedAverage, isNull);
    });

    test('returns null when all marks have weight 0', () {
      final sg = SubjectGrades(
        subjectName: 'Math',
        subjectId: 1,
        resolvedMarks: [_resolved(effectiveValue: 5, weight: 0)],
      );
      expect(sg.weightedAverage, isNull);
    });

    test('calculates simple average for equal weights', () {
      final sg = SubjectGrades(
        subjectName: 'Math',
        subjectId: 1,
        resolvedMarks: [
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
        resolvedMarks: [
          _resolved(effectiveValue: 5, weight: 3),
          _resolved(id: 2, effectiveValue: 3),
        ],
      );
      expect(sg.weightedAverage, closeTo(4.5, 0.01));
    });

    test('ignores marks that do not count to average', () {
      final sg = SubjectGrades(
        subjectName: 'Math',
        subjectId: 1,
        resolvedMarks: [
          _resolved(effectiveValue: 4),
          _resolved(id: 2, countsToAverage: false),
        ],
      );
      expect(sg.weightedAverage, 4.0);
    });

    test('ignores marks with zero weight', () {
      final sg = SubjectGrades(
        subjectName: 'Math',
        subjectId: 1,
        resolvedMarks: [
          _resolved(effectiveValue: 4),
          _resolved(id: 2, effectiveValue: 2, weight: 0),
        ],
      );
      expect(sg.weightedAverage, 4.0);
    });
  });

  group('gradeColor', () {
    test('returns excellent for >= 5.5', () {
      expect(gradeColor(6), AppColors.gradeExcellent);
      expect(gradeColor(5.5), AppColors.gradeExcellent);
    });

    test('returns veryGood for >= 4.5', () {
      expect(gradeColor(5), AppColors.gradeVeryGood);
      expect(gradeColor(4.5), AppColors.gradeVeryGood);
    });

    test('returns good for >= 3.5', () {
      expect(gradeColor(4), AppColors.gradeGood);
      expect(gradeColor(3.5), AppColors.gradeGood);
    });

    test('returns satisfactory for >= 2.5', () {
      expect(gradeColor(3), AppColors.gradeSatisfactory);
      expect(gradeColor(2.5), AppColors.gradeSatisfactory);
    });

    test('returns acceptable for >= 1.5', () {
      expect(gradeColor(2), AppColors.gradeAcceptable);
      expect(gradeColor(1.5), AppColors.gradeAcceptable);
    });

    test('returns failing for < 1.5', () {
      expect(gradeColor(1), AppColors.gradeFailing);
      expect(gradeColor(0.5), AppColors.gradeFailing);
    });

    test('returns satisfactory for null', () {
      expect(gradeColor(null), AppColors.gradeSatisfactory);
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
      final resolved = [
        _resolved(effectiveValue: 5),
        _resolved(id: 2, effectiveValue: 5),
        _resolved(id: 3, effectiveValue: 4),
        _resolved(id: 4, effectiveValue: 3),
      ];
      final dist = gradeDistribution(resolved);
      expect(dist['5'], 2);
      expect(dist['4'], 1);
      expect(dist['3'], 1);
    });

    test('ignores resolved marks with null effectiveValue', () {
      final resolved = [_resolved(effectiveValue: 5), _resolved(id: 2)];
      final dist = gradeDistribution(resolved);
      expect(dist.length, 1);
      expect(dist['5'], 1);
    });
  });
}
