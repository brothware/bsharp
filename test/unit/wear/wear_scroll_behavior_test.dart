import 'package:bsharp/wear/wear_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WearScrollBehavior', () {
    testWidgets('buildOverscrollIndicator returns the child unchanged', (
      tester,
    ) async {
      const child = SizedBox();
      late Widget result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = WearScrollBehavior().buildOverscrollIndicator(
                context,
                child,
                const ScrollableDetails(direction: AxisDirection.down),
              );
              return const SizedBox();
            },
          ),
        ),
      );

      expect(identical(result, child), isTrue);
    });

    testWidgets('no glow indicator paints when a wear list overscrolls', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          scrollBehavior: WearScrollBehavior(),
          home: Scaffold(
            body: ListView(
              children: List.generate(
                5,
                (i) => SizedBox(height: 40, child: Text('item $i')),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.drag(find.text('item 0'), const Offset(0, 300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(GlowingOverscrollIndicator), findsNothing);
      expect(find.byType(StretchingOverscrollIndicator), findsNothing);
    });
  });
}
