import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:bsharp/wear/widgets/wear_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wear_os_scrollbar/wear_os_scrollbar.dart';

Widget _app(
  WearScreenShape shape, {
  Widget? edgeContent,
  ScrollController? scrollController,
  Widget? child,
}) {
  return ProviderScope(
    overrides: [wearScreenShapeProvider.overrideWith((_) => shape)],
    child: MaterialApp(
      home: Scaffold(
        body: WearScaffold(
          edgeContent: edgeContent,
          scrollController: scrollController,
          child: child ?? Container(key: const Key('content')),
        ),
      ),
    ),
  );
}

void main() {
  group('WearScaffold', () {
    testWidgets('round content box keeps all four corners inside the circle', (
      tester,
    ) async {
      const size = Size(227, 227);
      tester.view.physicalSize = const Size(454, 454);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(WearScreenShape.round));
      await tester.pumpAndSettle();

      final box = tester.getRect(find.byKey(const Key('content')));
      final centre = Offset(size.width / 2, size.height / 2);
      final radius = size.width / 2;
      for (final corner in [
        box.topLeft,
        box.topRight,
        box.bottomLeft,
        box.bottomRight,
      ]) {
        expect(
          (corner - centre).distance,
          lessThanOrEqualTo(radius),
          reason: 'corner $corner falls outside the circle',
        );
      }
    });

    testWidgets('rectangular shape leaves a margin on all four sides', (
      tester,
    ) async {
      const size = Size(201, 238);
      tester.view.physicalSize = const Size(402, 476);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(WearScreenShape.rectangular));
      await tester.pumpAndSettle();

      final box = tester.getRect(find.byKey(const Key('content')));

      expect(box.left, greaterThan(0));
      expect(box.top, greaterThan(0));
      expect(box.right, lessThan(size.width));
      expect(box.bottom, lessThan(size.height));
    });

    testWidgets('edgeContent is not inside the content inset', (tester) async {
      tester.view.physicalSize = const Size(454, 454);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _app(
          WearScreenShape.round,
          edgeContent: Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(child: Container(key: const Key('edge'))),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.ancestor(
          of: find.byKey(const Key('edge')),
          matching: find.byKey(const Key('content')),
        ),
        findsNothing,
      );

      final contentBox = tester.getRect(find.byKey(const Key('content')));
      final edgeBox = tester.getRect(find.byKey(const Key('edge')));
      expect(edgeBox.right, greaterThan(contentBox.right));
    });
    testWidgets('the scrollbar arc spans the screen, not the inset content', (
      tester,
    ) async {
      const size = Size(227, 227);
      tester.view.physicalSize = const Size(454, 454);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _app(
          WearScreenShape.round,
          scrollController: controller,
          child: ListView(
            controller: controller,
            children: [
              for (var i = 0; i < 40; i++)
                SizedBox(height: 40, child: Text('row $i')),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final arc = tester.getRect(find.byType(WearOsScrollbar));
      expect(
        arc.size,
        size,
        reason:
            'the curved indicator is drawn on a circle inscribed in its own '
            'box, so anything smaller than the screen paints it on top of '
            'the content instead of along the bezel',
      );
    });

    testWidgets('no scrollbar is built without a controller', (tester) async {
      tester.view.physicalSize = const Size(454, 454);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(WearScreenShape.round));
      await tester.pumpAndSettle();

      expect(find.byType(WearOsScrollbar), findsNothing);
    });
  });
}
