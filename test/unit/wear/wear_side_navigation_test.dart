import 'package:bsharp/wear/widgets/wear_side_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app({VoidCallback? onPrevious, VoidCallback? onNext}) {
  return MaterialApp(
    home: Scaffold(
      body: Stack(
        children: [
          const SizedBox.expand(),
          WearSideNavigation(
            onPrevious: onPrevious ?? () {},
            onNext: onNext ?? () {},
          ),
        ],
      ),
    ),
  );
}

void main() {
  group('WearSideNavigation', () {
    testWidgets('sits at the left and right edges, vertically centred', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(454, 454);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      final previous = tester.getRect(find.byIcon(Icons.chevron_left));
      final next = tester.getRect(find.byIcon(Icons.chevron_right));
      const middle = 227 / 2;

      expect(previous.center.dy, closeTo(middle, 1));
      expect(next.center.dy, closeTo(middle, 1));
      expect(
        previous.center.dx,
        lessThan(middle),
        reason: 'previous belongs on the left',
      );
      expect(next.center.dx, greaterThan(middle));
    });

    testWidgets('both targets are at least 48dp', (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      for (final icon in [Icons.chevron_left, Icons.chevron_right]) {
        final target = find.ancestor(
          of: find.byIcon(icon),
          matching: find.byType(SizedBox),
        );
        final size = tester.getSize(target.first);
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      }
    });

    testWidgets('each side fires its own callback', (tester) async {
      var previous = 0;
      var next = 0;

      await tester.pumpWidget(
        _app(onPrevious: () => previous++, onNext: () => next++),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pump();
      expect((previous, next), (1, 0));

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pump();
      expect((previous, next), (1, 1));
    });
  });
}
