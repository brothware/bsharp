import 'package:bsharp/wear/widgets/wear_pinned_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WearPinnedHeader', () {
    testWidgets('paints an opaque background from the theme surface', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorScheme: const ColorScheme.light()),
          home: const Scaffold(
            body: WearPinnedHeader(child: Text('header')),
          ),
        ),
      );
      await tester.pump();

      final coloredBox = tester.widget<ColoredBox>(
        find.descendant(
          of: find.byType(WearPinnedHeader),
          matching: find.byType(ColoredBox),
        ),
      );
      final theme = Theme.of(tester.element(find.text('header')));
      expect(coloredBox.color, theme.colorScheme.surface);
    });

    testWidgets('reserves at least its minHeight', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WearPinnedHeader(
              minHeight: 50,
              child: SizedBox(height: 4),
            ),
          ),
        ),
      );
      await tester.pump();

      final size = tester.getSize(find.byType(WearPinnedHeader));
      expect(size.height, greaterThanOrEqualTo(50));
    });

    testWidgets(
      'pinned header content and list content below it never overlap',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  const WearPinnedHeader(child: Text('Header')),
                  Expanded(
                    child: ListView(
                      children: List.generate(
                        10,
                        (i) => Text('item $i'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pump();

        final headerBottom = tester.getBottomLeft(find.text('Header')).dy;
        final firstItemTop = tester.getTopLeft(find.text('item 0')).dy;
        expect(headerBottom, lessThanOrEqualTo(firstItemTop));
      },
    );
  });
}
