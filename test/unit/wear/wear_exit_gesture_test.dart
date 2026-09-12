import 'package:bsharp/wear/widgets/wear_swipe_dismiss.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WearSwipeDismiss onDismiss', () {
    testWidgets('a rightward drag past the threshold triggers onDismiss', (
      tester,
    ) async {
      var dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WearSwipeDismiss(
              onDismiss: () => dismissed = true,
              child: const SizedBox.expand(key: Key('top-level')),
            ),
          ),
        ),
      );

      await tester.dragFrom(const Offset(10, 300), const Offset(300, 0));
      await tester.pumpAndSettle();

      expect(dismissed, isTrue);
    });

    testWidgets('a drag below the threshold does not trigger onDismiss', (
      tester,
    ) async {
      var dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WearSwipeDismiss(
              onDismiss: () => dismissed = true,
              child: const SizedBox.expand(key: Key('top-level')),
            ),
          ),
        ),
      );

      await tester.dragFrom(const Offset(10, 300), const Offset(20, 0));
      await tester.pumpAndSettle();

      expect(dismissed, isFalse);
    });

    testWidgets('an upward overscroll no longer triggers onDismiss', (
      tester,
    ) async {
      var dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WearSwipeDismiss(
              onDismiss: () => dismissed = true,
              child: ListView(
                key: const Key('top-level-list'),
                children: const [SizedBox(height: 40)],
              ),
            ),
          ),
        ),
      );

      await tester.dragFrom(const Offset(150, 10), const Offset(0, 200));
      await tester.pumpAndSettle();

      expect(dismissed, isFalse);
    });
  });
}
