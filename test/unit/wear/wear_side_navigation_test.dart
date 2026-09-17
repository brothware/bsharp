import 'package:bsharp/wear/widgets/wear_side_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app({
  VoidCallback? onPrevious,
  VoidCallback? onNext,
  ScrollController? scrollController,
}) {
  final controller = scrollController ?? ScrollController();
  return MaterialApp(
    home: Scaffold(
      body: Stack(
        children: [
          ListView(
            controller: controller,
            children: [
              for (var i = 0; i < 40; i++)
                SizedBox(height: 40, child: Text('row $i')),
            ],
          ),
          WearSideNavigation(
            onPrevious: onPrevious ?? () {},
            onNext: onNext ?? () {},
            scrollController: controller,
          ),
        ],
      ),
    ),
  );
}

double _chevronOpacity(WidgetTester tester) => tester
    .widget<AnimatedOpacity>(
      find.ancestor(
        of: find.byIcon(Icons.chevron_right),
        matching: find.byType(AnimatedOpacity),
      ),
    )
    .opacity;

void main() {
  group('WearSideNavigation', () {
    testWidgets('gets out of the way while the scroll pill is up', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_app(scrollController: controller));
      await tester.pumpAndSettle();

      expect(_chevronOpacity(tester), 1, reason: 'nothing is scrolling yet');

      controller.jumpTo(120);
      await tester.pump();

      expect(
        _chevronOpacity(tester),
        0,
        reason: 'the pill is drawn on the same edge as the right chevron',
      );

      await tester.pump(const Duration(milliseconds: 2000));
      await tester.pumpAndSettle();

      expect(_chevronOpacity(tester), 1, reason: 'the pill has gone');
    });

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
