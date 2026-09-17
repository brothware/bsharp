import 'package:bsharp/domain/entities/resolved_grade.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:bsharp/wear/screens/wear_grades_detail_screen.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _card(SharedPreferences prefs, {String displayValue = '5'}) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      wearScreenShapeProvider.overrideWith((_) => WearScreenShape.round),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: WearGradeDetailScreen(
          grade: ResolvedGrade(
            id: 1,
            subjectName: 'Chemistry',
            categoryName: 'Quiz',
            displayValue: displayValue,
            date: DateTime(2026, 7, 28),
            effectiveValue: 5,
            weight: 2,
          ),
          subjectName: 'Chemistry',
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('the grade sits in the middle of its chip', (tester) async {
    tester.view.physicalSize = const Size(454, 454);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(_card(prefs));
    await tester.pumpAndSettle();

    // The chip has a minimum width, so the text box is wider than the digit.
    // Measure where the digit lands inside that box, not where the box lands:
    // the box is centred either way.
    final paragraph = tester.renderObject<RenderParagraph>(
      find.text('5').first,
    );
    final glyph = paragraph
        .getBoxesForSelection(
          const TextSelection(baseOffset: 0, extentOffset: 1),
        )
        .first
        .toRect();

    expect(
      glyph.center.dx,
      closeTo(paragraph.size.width / 2, 0.5),
      reason:
          'the chip is wider than the grade, and all of that slack was '
          'falling on one side of the digit',
    );
  });

  testWidgets('the grade card keeps every line inside the round glass', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(454, 454);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          wearScreenShapeProvider.overrideWith((_) => WearScreenShape.round),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: WearGradeDetailScreen(
              grade: ResolvedGrade(
                id: 1,
                subjectName: 'Chemistry',
                categoryName: 'Quiz',
                displayValue: '5',
                date: DateTime(2026, 7, 28),
                effectiveValue: 5,
                weight: 2,
              ),
              subjectName: 'Chemistry',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    const radius = 227.0 / 2;
    const centre = Offset(radius, radius);

    for (final text in tester.widgetList<Text>(find.byType(Text))) {
      final box = tester.getRect(find.byWidget(text));
      for (final corner in [
        box.topLeft,
        box.topRight,
        box.bottomLeft,
        box.bottomRight,
      ]) {
        final away = (corner - centre).distance;
        expect(
          away,
          lessThanOrEqualTo(radius),
          reason:
              '"${text.data}" reaches $away from the middle on a watch whose '
              'glass stops at $radius, so the bezel cuts it off',
        );
      }
    }
  });
}
