import 'package:bsharp/app/translation_provider.dart';
import 'package:bsharp/domain/entities/resolved_grade.dart';
import 'package:bsharp/presentation/grades/widgets/grade_detail_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _grade = ResolvedGrade(
  id: 1,
  subjectName: 'Matematyka',
  categoryName: 'Sprawdzian',
  displayValue: '5',
  date: DateTime(2026, 2, 27),
  effectiveValue: 5,
  comment: 'Bardzo dobrze',
);

Widget _sheet({required bool isAvailable}) {
  return ProviderScope(
    overrides: [
      isTranslationAvailableProvider.overrideWithValue(isAvailable),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: GradeDetailSheet(grade: _grade, subjectName: 'Matematyka'),
      ),
    ),
  );
}

void main() {
  testWidgets('offers translation when it is available', (tester) async {
    await tester.pumpWidget(_sheet(isAvailable: true));

    expect(find.byIcon(Icons.translate), findsOneWidget);
  });

  testWidgets('hides translation when the app speaks the content language', (
    tester,
  ) async {
    await tester.pumpWidget(_sheet(isAvailable: false));

    expect(find.byIcon(Icons.translate), findsNothing);
  });
}
