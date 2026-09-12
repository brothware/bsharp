import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:bsharp/wear/widgets/wear_scaffold.dart';
import 'package:bsharp/wear/widgets/wear_tile_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildHeader({required WearScreenShape shape, Widget? trailing}) {
  return MaterialApp(
    home: Scaffold(
      body: WearDisplayScope(
        display: WearDisplay(shape: shape, sizeDp: const Size(400, 400)),
        child: WearTileHeader(
          icon: Icons.grade,
          title: 'Grades',
          trailing: trailing,
        ),
      ),
    ),
  );
}

void main() {
  group('WearTileHeader', () {
    testWidgets('rectangular renders Row with icon and title', (tester) async {
      await tester.pumpWidget(_buildHeader(shape: WearScreenShape.rectangular));

      expect(find.byType(Row), findsOneWidget);
      expect(find.text('Grades'), findsOneWidget);
      expect(find.byIcon(Icons.grade), findsOneWidget);
    });

    testWidgets('round renders centered Column with icon and title', (
      tester,
    ) async {
      await tester.pumpWidget(_buildHeader(shape: WearScreenShape.round));

      expect(find.byType(Row), findsNothing);
      expect(find.byIcon(Icons.grade), findsOneWidget);
      expect(find.text('Grades'), findsOneWidget);
    });

    testWidgets('trailing shown in rectangular mode', (tester) async {
      await tester.pumpWidget(
        _buildHeader(
          shape: WearScreenShape.rectangular,
          trailing: const Text('42'),
        ),
      );

      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('trailing shown in round mode', (tester) async {
      await tester.pumpWidget(
        _buildHeader(shape: WearScreenShape.round, trailing: const Text('42')),
      );

      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('paints an opaque surface background in rectangular mode', (
      tester,
    ) async {
      await tester.pumpWidget(_buildHeader(shape: WearScreenShape.rectangular));

      final theme = Theme.of(tester.element(find.byType(WearTileHeader)));
      final coloredBox = tester.widget<ColoredBox>(
        find
            .descendant(
              of: find.byType(WearTileHeader),
              matching: find.byType(ColoredBox),
            )
            .first,
      );
      expect(coloredBox.color, theme.colorScheme.surface);
    });

    testWidgets('paints an opaque surface background in round mode', (
      tester,
    ) async {
      await tester.pumpWidget(_buildHeader(shape: WearScreenShape.round));

      final theme = Theme.of(tester.element(find.byType(WearTileHeader)));
      final coloredBox = tester.widget<ColoredBox>(
        find
            .descendant(
              of: find.byType(WearTileHeader),
              matching: find.byType(ColoredBox),
            )
            .first,
      );
      expect(coloredBox.color, theme.colorScheme.surface);
    });

    testWidgets(
      'a scrolled list never paints above the header, at either shape',
      (tester) async {
        Future<void> expectNoOverlap(WearScreenShape shape) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: WearDisplayScope(
                  display: WearDisplay(
                    shape: shape,
                    sizeDp: const Size(400, 400),
                  ),
                  child: Column(
                    children: [
                      const WearTileHeader(icon: Icons.grade, title: 'Grades'),
                      Expanded(
                        child: ListView.builder(
                          itemCount: 30,
                          itemBuilder: (context, index) => SizedBox(
                            key: Key('row-$index'),
                            height: 48,
                            child: Text('Row $index'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );

          await tester.drag(find.byType(ListView), const Offset(0, -2000));
          await tester.pumpAndSettle();

          final headerRect = tester.getRect(find.byType(WearTileHeader));
          final rowFinder = find.byKey(const Key('row-20'));
          if (rowFinder.evaluate().isEmpty) return;
          final rowRect = tester.getRect(rowFinder);

          expect(
            rowRect.top,
            greaterThanOrEqualTo(headerRect.bottom),
            reason: 'row-20 painted above the header bottom edge',
          );
        }

        await expectNoOverlap(WearScreenShape.rectangular);
        await expectNoOverlap(WearScreenShape.round);
      },
    );
  });
}
