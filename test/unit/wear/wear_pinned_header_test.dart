import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:bsharp/wear/widgets/wear_pinned_header.dart';
import 'package:bsharp/wear/widgets/wear_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The header only ever lives inside a WearScaffold, which is what tells it
/// how much the round glass takes off its sides.
Widget _hosted(Widget child) {
  return WearDisplayScope(
    display: const WearDisplay(
      shape: WearScreenShape.round,
      sizeDp: Size(227, 227),
    ),
    child: child,
  );
}

void main() {
  group('WearPinnedHeader', () {
    testWidgets('paints an opaque background from the theme surface', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorScheme: const ColorScheme.light()),
          home: Scaffold(
            body: _hosted(const WearPinnedHeader(child: Text('header'))),
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
        MaterialApp(
          home: Scaffold(
            body: _hosted(
              const WearPinnedHeader(
                minHeight: 50,
                child: SizedBox(height: 4),
              ),
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
              body: _hosted(
                Column(
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
