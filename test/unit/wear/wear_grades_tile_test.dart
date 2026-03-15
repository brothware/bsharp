import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/domain/entities/resolved_grade.dart';
import 'package:bsharp/domain/grade_utils.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:bsharp/presentation/grades/providers/grades_providers.dart';
import 'package:bsharp/wear/screens/wear_grades_tile.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/credential_storage_test.dart';

ResolvedGrade _grade({
  int id = 1,
  double? effectiveValue = 5.0,
  String? displayValue,
  DateTime? date,
}) {
  return ResolvedGrade(
    id: id,
    subjectName: 'Test',
    categoryName: '',
    displayValue:
        displayValue ??
        (effectiveValue != null
            ? (effectiveValue == effectiveValue.roundToDouble()
                  ? effectiveValue.toInt().toString()
                  : effectiveValue.toStringAsFixed(1))
            : '?'),
    date: date ?? DateTime.now(),
    effectiveValue: effectiveValue,
    countsToAverage: effectiveValue != null,
  );
}

Future<Widget> _buildTile({
  List<SubjectGrades> subjectGrades = const [],
  Set<int> newIds = const {},
}) async {
  SharedPreferences.setMockInitialValues({
    if (newIds.isNotEmpty)
      'new_grade_ids': newIds.map((e) => e.toString()).toList(),
  });
  final prefs = await SharedPreferences.getInstance();
  final storage = CredentialStorage(store: FakeKeyValueStore());
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      credentialStorageProvider.overrideWithValue(storage),
      wearScreenShapeProvider.overrideWith((_) => WearScreenShape.rectangular),
      subjectGradesProvider.overrideWith((ref) => subjectGrades),
    ],
    child: const MaterialApp(home: Scaffold(body: WearGradesTile())),
  );
}

SubjectGrades _sg(List<ResolvedGrade> grades) {
  return SubjectGrades(
    subjectName: 'Test',
    subjectId: 1,
    grades: grades,
  );
}

void main() {
  group('WearGradesTile', () {
    testWidgets('shows empty state when no marks', (tester) async {
      await tester.pumpWidget(await _buildTile());
      await tester.pump();

      expect(find.text('No grades'), findsOneWidget);
      expect(find.byIcon(Icons.grade_outlined), findsOneWidget);
    });

    testWidgets('shows recent grades with values', (tester) async {
      await tester.pumpWidget(
        await _buildTile(
          subjectGrades: [
            _sg([_grade(), _grade(id: 2, effectiveValue: 3)]),
          ],
        ),
      );
      await tester.pump();

      expect(find.text('5'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Test'), findsWidgets);
    });

    testWidgets('shows at most 5 recent grades', (tester) async {
      final grades = List.generate(
        8,
        (i) => _grade(
          id: i + 1,
          effectiveValue: (i + 1).toDouble(),
          date: DateTime.now().subtract(Duration(days: i)),
        ),
      );

      await tester.pumpWidget(
        await _buildTile(subjectGrades: [_sg(grades)]),
      );
      await tester.pump();

      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('shows NEW badge for new grades', (tester) async {
      await tester.pumpWidget(
        await _buildTile(
          subjectGrades: [
            _sg([_grade()]),
          ],
          newIds: {1},
        ),
      );
      await tester.pump();

      expect(find.text('NEW'), findsOneWidget);
    });

    testWidgets('shows total count in header', (tester) async {
      await tester.pumpWidget(
        await _buildTile(
          subjectGrades: [
            _sg([_grade(), _grade(id: 2), _grade(id: 3)]),
          ],
        ),
      );
      await tester.pump();

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shows ? for null markValue', (tester) async {
      await tester.pumpWidget(
        await _buildTile(
          subjectGrades: [
            _sg([_grade(effectiveValue: null)]),
          ],
        ),
      );
      await tester.pump();

      expect(find.text('?'), findsOneWidget);
    });
  });
}
