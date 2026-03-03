import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:bsharp/wear/widgets/wear_screen_layout.dart';

Widget _buildApp(WearScreenShape shape) {
  return ProviderScope(
    overrides: [wearScreenShapeProvider.overrideWith((_) => shape)],
    child: MaterialApp(
      home: Scaffold(
        body: WearScreenLayout(child: Container(key: const Key('content'))),
      ),
    ),
  );
}

void main() {
  group('WearScreenLayout', () {
    testWidgets('rectangular shape wraps child in SafeArea', (tester) async {
      await tester.pumpWidget(_buildApp(WearScreenShape.rectangular));

      expect(find.byType(SafeArea), findsOneWidget);
      expect(find.byKey(const Key('content')), findsOneWidget);
    });

    testWidgets('round shape applies proportional padding', (tester) async {
      await tester.pumpWidget(_buildApp(WearScreenShape.round));

      expect(find.byType(SafeArea), findsNothing);

      final padding = tester.widget<Padding>(
        find.descendant(
          of: find.byType(WearScreenLayout),
          matching: find.byType(Padding),
        ),
      );

      final insets = padding.padding.resolve(TextDirection.ltr);
      expect(insets.left, greaterThan(0));
      expect(insets.right, greaterThan(0));
      expect(insets.top, greaterThan(0));
      expect(insets.bottom, greaterThan(0));
      expect(insets.top, greaterThan(insets.bottom));
    });
  });
}
