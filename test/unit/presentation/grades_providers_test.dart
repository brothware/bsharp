import 'package:bsharp/domain/entities/resolved_grade.dart';
import 'package:bsharp/domain/entities/sync_action.dart';
import 'package:bsharp/domain/entities/term.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:bsharp/presentation/grades/providers/grades_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  ResolvedGrade grade({
    int id = 1,
    String subjectName = 'Math',
    double? effectiveValue = 5,
    String? displayValue,
    int weight = 1,
    bool countsToAverage = true,
    DateTime? date,
    int? subjectId,
  }) {
    return ResolvedGrade(
      id: id,
      subjectName: subjectName,
      categoryName: 'Exam',
      displayValue:
          displayValue ??
          (effectiveValue != null
              ? (effectiveValue == effectiveValue.roundToDouble()
                    ? effectiveValue.toInt().toString()
                    : effectiveValue.toStringAsFixed(1))
              : '?'),
      date: date ?? DateTime(2026, 2, 27),
      effectiveValue: effectiveValue,
      weight: weight,
      countsToAverage: countsToAverage,
      subjectId: subjectId,
    );
  }

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('currentTermProvider', () {
    test('returns null when no terms', () {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          termsProvider.overrideWithBuild((ref, _) => []),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(currentTermProvider), isNull);
    });

    test('returns selected term when id set', () {
      final term1 = Term(
        id: 1,
        name: 'Semester 1',
        type: TermType.semester,
        startDate: DateTime(2025, 9),
        endDate: DateTime(2026, 1, 31),
      );
      final term2 = Term(
        id: 2,
        name: 'Semester 2',
        type: TermType.semester,
        startDate: DateTime(2026, 2),
        endDate: DateTime(2026, 6, 30),
      );

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          termsProvider.overrideWithBuild((ref, _) => [term1, term2]),
          selectedTermIdProvider.overrideWithBuild((ref, _) => 2),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(currentTermProvider)?.id, 2);
    });

    test('auto-selects current term by date', () {
      final past = Term(
        id: 1,
        name: 'Past',
        type: TermType.semester,
        startDate: DateTime(2025),
        endDate: DateTime(2025, 6, 30),
      );
      final current = Term(
        id: 2,
        name: 'Current',
        type: TermType.semester,
        startDate: DateTime(2025, 9),
        endDate: DateTime(2027, 6, 30),
      );

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          termsProvider.overrideWithBuild((ref, _) => [past, current]),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(currentTermProvider)?.id, 2);
    });

    test('falls back to first term', () {
      final term = Term(
        id: 1,
        name: 'Old',
        type: TermType.year,
        startDate: DateTime(2020, 9),
        endDate: DateTime(2021, 6, 30),
      );

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          termsProvider.overrideWithBuild((ref, _) => [term]),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(currentTermProvider)?.id, 1);
    });
  });

  group('subjectGradesProvider', () {
    test('returns empty list when no grades', () {
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      expect(container.read(subjectGradesProvider), isEmpty);
    });

    test('groups grades by subject name', () {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          resolvedGradesProvider.overrideWithBuild(
            (ref, _) => [
              grade(subjectId: 100),
              grade(id: 2, effectiveValue: 4, subjectId: 100),
              grade(
                id: 3,
                subjectName: 'Polish',
                effectiveValue: 3,
                subjectId: 200,
              ),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(subjectGradesProvider);
      expect(result.length, 2);

      final math = result.firstWhere((sg) => sg.subjectName == 'Math');
      expect(math.grades.length, 2);

      final polish = result.firstWhere((sg) => sg.subjectName == 'Polish');
      expect(polish.grades.length, 1);
    });

    test(
      'resolves scale-based grades with abbreviation and effective value',
      () {
        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            resolvedGradesProvider.overrideWithBuild(
              (ref, _) => [
                grade(
                  subjectName: 'Music',
                  displayValue: '4+',
                  effectiveValue: 4.5,
                  subjectId: 100,
                ),
              ],
            ),
          ],
        );
        addTearDown(container.dispose);

        final result = container.read(subjectGradesProvider);
        expect(result.length, 1);
        final g = result.first.grades.first;
        expect(g.displayValue, '4+');
        expect(g.effectiveValue, 4.5);
      },
    );

    test('resolves point-based grades with value/max format', () {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          resolvedGradesProvider.overrideWithBuild(
            (ref, _) => [
              grade(
                subjectName: 'Education',
                displayValue: '8/10',
                effectiveValue: 8,
                subjectId: 100,
              ),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(subjectGradesProvider);
      final g = result.first.grades.first;
      expect(g.displayValue, '8/10');
    });

    test('sorts subjects alphabetically', () {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          resolvedGradesProvider.overrideWithBuild(
            (ref, _) => [
              grade(subjectName: 'Biology', subjectId: 200),
              grade(id: 2, subjectName: 'English', subjectId: 100),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(subjectGradesProvider);
      expect(result[0].subjectName, 'Biology');
      expect(result[1].subjectName, 'English');
    });

    test('sorts grades by date ascending within subject', () {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          resolvedGradesProvider.overrideWithBuild(
            (ref, _) => [
              grade(
                effectiveValue: 3,
                date: DateTime(2026, 2, 27),
                subjectId: 100,
              ),
              grade(
                id: 2,
                date: DateTime(2026, 3),
                subjectId: 100,
              ),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(subjectGradesProvider);
      expect(result.first.grades.first.id, 1);
      expect(result.first.grades.last.id, 2);
    });
  });

  group('overallWeightedAverageProvider', () {
    test('returns null when no subjects', () {
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      expect(container.read(overallWeightedAverageProvider), isNull);
    });

    test('calculates mean of subject weighted averages', () {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          resolvedGradesProvider.overrideWithBuild(
            (ref, _) => [
              grade(subjectName: 'A', subjectId: 100),
              grade(
                id: 2,
                subjectName: 'B',
                effectiveValue: 3,
                subjectId: 200,
              ),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(overallWeightedAverageProvider), 4.0);
    });
  });

  group('overallSimpleAverageProvider', () {
    test('returns null when no subjects', () {
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      expect(container.read(overallSimpleAverageProvider), isNull);
    });
  });

  group('gradeDistributionProvider', () {
    test('returns empty map for no grades', () {
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      expect(container.read(gradeDistributionProvider), isEmpty);
    });

    test('counts by rounded effective value', () {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          resolvedGradesProvider.overrideWithBuild(
            (ref, _) => [
              grade(subjectName: 'A', subjectId: 100),
              grade(id: 2, subjectName: 'A', subjectId: 100),
              grade(
                id: 3,
                subjectName: 'A',
                effectiveValue: 4,
                subjectId: 100,
              ),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      final dist = container.read(gradeDistributionProvider);
      expect(dist['5'], 2);
      expect(dist['4'], 1);
    });
  });
}
