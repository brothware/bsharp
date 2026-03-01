import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bsharp/wear/widgets/wear_forward_swipe.dart';

void main() {
  group('WearForwardSwipe', () {
    testWidgets('fires onTriggered when leftward drag exceeds threshold',
        (tester) async {
      var triggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WearForwardSwipe(
              onTriggered: () => triggered = true,
              child: const SizedBox.expand(child: Text('Content')),
            ),
          ),
        ),
      );

      await tester.drag(find.text('Content'), const Offset(-100, 0));
      await tester.pumpAndSettle();

      expect(triggered, isTrue);
    });

    testWidgets('does not fire when drag is below threshold', (tester) async {
      var triggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WearForwardSwipe(
              onTriggered: () => triggered = true,
              child: const SizedBox.expand(child: Text('Content')),
            ),
          ),
        ),
      );

      await tester.drag(find.text('Content'), const Offset(-30, 0));
      await tester.pumpAndSettle();

      expect(triggered, isFalse);
    });

    testWidgets('ignores rightward drag', (tester) async {
      var triggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WearForwardSwipe(
              onTriggered: () => triggered = true,
              child: const SizedBox.expand(child: Text('Content')),
            ),
          ),
        ),
      );

      await tester.drag(find.text('Content'), const Offset(100, 0));
      await tester.pumpAndSettle();

      expect(triggered, isFalse);
    });

    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WearForwardSwipe(
              onTriggered: () {},
              child: const Text('Hello'),
            ),
          ),
        ),
      );

      expect(find.text('Hello'), findsOneWidget);
    });
  });
}
