import 'package:bsharp/domain/entities/resolved_grade.dart';
import 'package:bsharp/presentation/grades/widgets/grade_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ResolvedGrade _resolved({
  double? effectiveValue = 5,
  String? displayValue,
  int weight = 1,
}) {
  return ResolvedGrade(
    id: 1,
    subjectName: 'Math',
    categoryName: 'Exam',
    displayValue:
        displayValue ??
        (effectiveValue != null
            ? (effectiveValue == effectiveValue.roundToDouble()
                  ? effectiveValue.toInt().toString()
                  : effectiveValue.toStringAsFixed(1))
            : '?'),
    date: DateTime(2026, 2, 27),
    effectiveValue: effectiveValue,
    weight: weight,
  );
}

void main() {
  group('GradeChip', () {
    testWidgets('displays grade value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: GradeChip(grade: _resolved())),
        ),
      );

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('displays scale abbreviation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GradeChip(
              grade: _resolved(
                effectiveValue: 4.5,
                displayValue: '4+',
              ),
            ),
          ),
        ),
      );

      expect(find.text('4+'), findsOneWidget);
    });

    testWidgets('displays point-based format', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GradeChip(
              grade: _resolved(
                effectiveValue: 8,
                displayValue: '8/10',
              ),
            ),
          ),
        ),
      );

      expect(find.text('8/10'), findsOneWidget);
    });

    testWidgets('displays ? for null value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GradeChip(grade: _resolved(effectiveValue: null)),
          ),
        ),
      );

      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('shows NEW badge when isNew', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GradeChip(grade: _resolved(), isNew: true),
          ),
        ),
      );

      expect(find.text('NEW'), findsOneWidget);
    });

    testWidgets('hides NEW badge when not new', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: GradeChip(grade: _resolved())),
        ),
      );

      expect(find.text('NEW'), findsNothing);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GradeChip(
              grade: _resolved(),
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('5'));
      expect(tapped, isTrue);
    });
  });
}
