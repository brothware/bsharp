import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:bsharp/wear/widgets/wear_list_item.dart';
import 'package:bsharp/wear/widgets/wear_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wear_os_scrollbar/wear_os_scrollbar.dart';

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

void main() {
  group('WearListItem', () {
    testWidgets('a round screen narrows its rows near the edges', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_list(WearScreenShape.round, controller));
      await tester.pumpAndSettle();

      expect(
        find.byType(WearOsExpressiveItem),
        findsWidgets,
        reason:
            'the screen keeps only a thin margin now, so a row at the top or '
            'bottom of the viewport has to give up the width the circle does',
      );
    });

    testWidgets('a rectangular screen leaves its rows alone', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _list(WearScreenShape.rectangular, controller),
      );
      await tester.pumpAndSettle();

      expect(find.byType(WearOsExpressiveItem), findsNothing);
    });
  });
}
