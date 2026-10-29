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

    testWidgets('a swipe handled in place leaves the screen at rest', (
      tester,
    ) async {
      var dismissals = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WearSwipeDismiss(
              onDismiss: () => dismissals++,
              child: const SizedBox.expand(key: Key('step')),
            ),
          ),
        ),
      );

      await tester.dragFrom(const Offset(10, 300), const Offset(300, 0));
      await tester.pumpAndSettle();
      final transform = tester.widget<Transform>(
        find
            .ancestor(
              of: find.byKey(const Key('step')),
              matching: find.byType(Transform),
            )
            .first,
      );
      expect(
        transform.transform.getTranslation().x,
        0,
        reason: 'the next step was drawn shifted off by the last swipe',
      );

      await tester.dragFrom(const Offset(10, 300), const Offset(5, 0));
      await tester.pumpAndSettle();
      expect(dismissals, 1, reason: 'a 5px nudge went back another step');
    });
  });
}
