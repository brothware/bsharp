import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/domain/entities/resolved_grade.dart';
import 'package:bsharp/domain/entities/sync_action.dart';
import 'package:bsharp/domain/entities/term.dart';
import 'package:bsharp/domain/grade_utils.dart';
import 'package:bsharp/presentation/grades/providers/grades_providers.dart';
import 'package:bsharp/wear/screens/wear_grades_detail_screen.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../data/credential_storage_test.dart';

ResolvedGrade _grade({
  int id = 1,
  double? effectiveValue = 5.0,
  String? displayValue,
}) {
  return ResolvedGrade(
    id: id,
    subjectName: 'Test',
    categoryName: '',
    displayValue:
        displayValue ??
        (effectiveValue != null ? effectiveValue.toInt().toString() : '?'),
    date: DateTime.now(),
    effectiveValue: effectiveValue,
    countsToAverage: effectiveValue != null,
  );
}

Widget _buildScreen({
  List<SubjectGrades> subjectGrades = const [],
  List<Term> terms = const [],
}) {
  final storage = CredentialStorage(store: FakeKeyValueStore());
  return ProviderScope(
    overrides: [
      credentialStorageProvider.overrideWithValue(storage),
      wearScreenShapeProvider.overrideWith((_) => WearScreenShape.rectangular),
      subjectGradesProvider.overrideWith((ref) => subjectGrades),
      termsProvider.overrideWithBuild((ref, _) => terms),
    ],
    child: const MaterialApp(home: WearGradesDetailScreen()),
  );
}

void main() {
  group('WearGradesDetailScreen', () {
    testWidgets('shows no grades when empty', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.text('No grades'), findsOneWidget);
    });

    testWidgets('shows subject sections with grades', (tester) async {
      await tester.pumpWidget(
        _buildScreen(
          subjectGrades: [
            SubjectGrades(
              subjectName: 'Mathematics',
              subjectId: 1,
              grades: [_grade()],
            ),
            SubjectGrades(
              subjectName: 'English',
              subjectId: 2,
              grades: [_grade(id: 2, effectiveValue: 4)],
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.text('English'), findsOneWidget);
      expect(find.text('Mathematics'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('shows term selector when multiple terms', (tester) async {
      final now = DateTime.now();
      await tester.pumpWidget(
        _buildScreen(
          terms: [
            Term(
              id: 1,
              name: 'Semester 1',
              type: TermType.semester,
              startDate: now.subtract(const Duration(days: 90)),
              endDate: now.add(const Duration(days: 90)),
            ),
            Term(
              id: 2,
              name: 'Semester 2',
              type: TermType.semester,
              startDate: now.add(const Duration(days: 91)),
              endDate: now.add(const Duration(days: 270)),
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('shows average for subject', (tester) async {
      await tester.pumpWidget(
        _buildScreen(
          subjectGrades: [
            SubjectGrades(
              subjectName: 'Mathematics',
              subjectId: 1,
              grades: [_grade(), _grade(id: 2, effectiveValue: 4)],
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.text('4.50'), findsOneWidget);
    });
  });
}
