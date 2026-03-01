import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/domain/entities/mark.dart';
import 'package:bsharp/domain/grade_utils.dart';
import 'package:bsharp/presentation/grades/providers/grades_providers.dart';
import 'package:bsharp/wear/screens/wear_grades_tile.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';

import '../data/credential_storage_test.dart';

Mark _mark({
  int id = 1,
  double? markValue = 5.0,
  String? comments,
  DateTime? date,
}) {
  return Mark(
    id: id,
    markGroupsId: 1,
    pupilUsersId: 1,
    teacherUsersId: 1,
    markValue: markValue,
    comments: comments,
    weight: 1,
    getDate: date ?? DateTime.now(),
    modified: 0,
  );
}

ResolvedMark _resolved({
  int id = 1,
  double? markValue = 5.0,
  String? displayValue,
  String? comments,
  DateTime? date,
}) {
  final mark = _mark(id: id, markValue: markValue, comments: comments, date: date);
  return ResolvedMark(
    mark: mark,
    displayValue: displayValue ?? (markValue != null
        ? (markValue == markValue.roundToDouble()
            ? markValue.toInt().toString()
            : markValue.toStringAsFixed(1))
        : '?'),
    effectiveValue: markValue,
    countsToAverage: markValue != null,
  );
}

Widget _buildTile({
  List<SubjectGrades> subjectGrades = const [],
  Set<int> newIds = const {},
}) {
  final storage = CredentialStorage(storage: FakeFlutterSecureStorage());
  return ProviderScope(
    overrides: [
      credentialStorageProvider.overrideWithValue(storage),
      wearScreenShapeProvider
          .overrideWith((_) => WearScreenShape.rectangular),
      subjectGradesProvider.overrideWith((ref) => subjectGrades),
      newGradeIdsProvider.overrideWith((ref) => newIds),
    ],
    child: const MaterialApp(
      home: Scaffold(body: WearGradesTile()),
    ),
  );
}

SubjectGrades _sg(List<ResolvedMark> resolvedMarks) {
  return SubjectGrades(
    subjectName: 'Test',
    subjectId: 1,
    resolvedMarks: resolvedMarks,
  );
}

void main() {
  group('WearGradesTile', () {
    testWidgets('shows empty state when no marks', (tester) async {
      await tester.pumpWidget(_buildTile());
      await tester.pump();

      expect(find.text('No grades'), findsOneWidget);
      expect(find.byIcon(Icons.grade_outlined), findsOneWidget);
    });

    testWidgets('shows recent grades with values', (tester) async {
      await tester.pumpWidget(_buildTile(subjectGrades: [
        _sg([
          _resolved(id: 1, markValue: 5.0),
          _resolved(id: 2, markValue: 3.0),
        ]),
      ]));
      await tester.pump();

      expect(find.text('5'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Test'), findsWidgets);
    });

    testWidgets('shows at most 5 recent grades', (tester) async {
      final resolvedMarks = List.generate(
        8,
        (i) => _resolved(
          id: i + 1,
          markValue: (i + 1).toDouble(),
          date: DateTime.now().subtract(Duration(days: i)),
        ),
      );

      await tester.pumpWidget(_buildTile(subjectGrades: [_sg(resolvedMarks)]));
      await tester.pump();

      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('shows NEW badge for new grades', (tester) async {
      await tester.pumpWidget(_buildTile(
        subjectGrades: [_sg([_resolved(id: 1, markValue: 5.0)])],
        newIds: {1},
      ));
      await tester.pump();

      expect(find.text('NEW'), findsOneWidget);
    });

    testWidgets('shows total count in header', (tester) async {
      await tester.pumpWidget(_buildTile(subjectGrades: [
        _sg([
          _resolved(id: 1),
          _resolved(id: 2),
          _resolved(id: 3),
        ]),
      ]));
      await tester.pump();

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shows ? for null markValue', (tester) async {
      await tester.pumpWidget(_buildTile(subjectGrades: [
        _sg([_resolved(id: 1, markValue: null)]),
      ]));
      await tester.pump();

      expect(find.text('?'), findsOneWidget);
    });
  });
}
