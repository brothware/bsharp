import 'package:bsharp/domain/entities/mark.dart';
import 'package:bsharp/domain/grade_utils.dart';
import 'package:bsharp/presentation/grades/widgets/grade_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Mark _mark({double? markValue = 5, int weight = 1}) {
  return Mark(
    id: 1,
    markGroupsId: 1,
    pupilUsersId: 1,
    teacherUsersId: 1,
    markValue: markValue,
    weight: weight,
    getDate: DateTime(2026, 2, 27),
    modified: 0,
  );
}

ResolvedMark _resolved({
  double? markValue = 5,
  String? displayValue,
  double? effectiveValue,
  int weight = 1,
}) {
  final mark = _mark(markValue: markValue, weight: weight);
  return ResolvedMark(
    mark: mark,
    displayValue:
        displayValue ??
        (markValue != null
            ? (markValue == markValue.roundToDouble()
                  ? markValue.toInt().toString()
                  : markValue.toStringAsFixed(1))
            : '?'),
    effectiveValue: effectiveValue ?? markValue,
  );
}

void main() {
  group('GradeChip', () {
    testWidgets('displays mark value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: GradeChip(resolvedMark: _resolved())),
        ),
      );

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('displays scale abbreviation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GradeChip(
              resolvedMark: _resolved(
                markValue: null,
                displayValue: '4+',
                effectiveValue: 4.5,
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
              resolvedMark: _resolved(
                markValue: 8,
                displayValue: '8/10',
                effectiveValue: 8,
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
            body: GradeChip(resolvedMark: _resolved(markValue: null)),
          ),
        ),
      );

      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('shows weight indicator when weight > 1', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: GradeChip(resolvedMark: _resolved(weight: 3))),
        ),
      );

      expect(find.text('w3'), findsOneWidget);
    });

    testWidgets('hides weight indicator when weight is 1', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: GradeChip(resolvedMark: _resolved())),
        ),
      );

      expect(find.text('w1'), findsNothing);
    });

    testWidgets('shows NEW badge when isNew', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GradeChip(resolvedMark: _resolved(), isNew: true),
          ),
        ),
      );

      expect(find.text('NEW'), findsOneWidget);
    });

    testWidgets('hides NEW badge when not new', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: GradeChip(resolvedMark: _resolved())),
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
              resolvedMark: _resolved(),
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
