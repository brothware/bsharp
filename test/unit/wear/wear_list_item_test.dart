import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:bsharp/wear/widgets/wear_list_item.dart';
import 'package:bsharp/wear/widgets/wear_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _list(WearScreenShape shape, ScrollController controller) {
  return MaterialApp(
    home: Scaffold(
      body: WearDisplayScope(
        display: WearDisplay(shape: shape, sizeDp: const Size(227, 227)),
        child: ListView.builder(
          controller: controller,
          itemCount: 20,
          itemBuilder: wearScaledItems(
            controller,
            (context, index) => SizedBox(height: 40, child: Text('row $index')),
          ),
        ),
      ),
    ),
  );
}

/// How wide a row is actually drawn, which the edge scaling shrinks even
/// though the row still measures its full size.
double _paintedWidth(WidgetTester tester, String label) =>
    tester.getRect(find.text(label)).width;

void main() {
  group('wearListPadding', () {
    const display = WearDisplay(
      shape: WearScreenShape.round,
      sizeDp: Size(227, 227),
    );

    test('leaves no room above the first row', () {
      expect(
        wearListPadding(display).top,
        0,
        reason:
            'scrolling above the top of the list is scrolling into '
            'nothing, and the list should stop where it starts',
      );
    });

    test('keeps room below so the last row can reach the middle', () {
      expect(wearListPadding(display).bottom, greaterThan(0));
    });

    test('a rectangular screen needs neither', () {
      expect(
        wearListPadding(
          const WearDisplay(
            shape: WearScreenShape.rectangular,
            sizeDp: Size(227, 227),
          ),
        ),
        EdgeInsets.zero,
      );
    });
  });

  group('WearListItem', () {
    testWidgets('a round screen paints its rows smaller near the edges', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_list(WearScreenShape.round, controller));
      await tester.pumpAndSettle();

      expect(
        _paintedWidth(tester, 'row 0'),
        lessThan(_paintedWidth(tester, 'row 7')),
        reason:
            'the screen keeps only a thin margin now, so a row at the top or '
            'bottom of the viewport has to give up the width the circle does',
      );
    });

    testWidgets('scaling a row never changes the space it occupies', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_list(WearScreenShape.round, controller));
      await tester.pumpAndSettle();

      Set<double> rowHeights() => tester
          .widgetList<WearListItem>(find.byType(WearListItem))
          .map((row) => tester.getSize(find.byWidget(row)).height)
          .toSet();

      expect(
        rowHeights(),
        {40.0},
        reason:
            'every row is 40 high, and a row that shrinks its own extent as '
            'it nears the edge makes the extent a function of the scroll '
            'offset - which the sliver then corrects, moving the offset, '
            'rescaling the rows, and never settling',
      );

      controller.jumpTo(120);
      await tester.pumpAndSettle();

      expect(rowHeights(), {40.0}, reason: 'still true once scrolled');
    });

    testWidgets('a rectangular screen leaves its rows alone', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _list(WearScreenShape.rectangular, controller),
      );
      await tester.pumpAndSettle();

      expect(
        _paintedWidth(tester, 'row 0'),
        _paintedWidth(tester, 'row 7'),
      );
    });
  });
}
