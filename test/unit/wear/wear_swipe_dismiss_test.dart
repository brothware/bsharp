import 'package:bsharp/wear/widgets/wear_swipe_dismiss.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WearSwipeDismiss', () {
    testWidgets('dragging over transparent background still pops the route', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const Scaffold(
                        body: WearSwipeDismiss(
                          child: SizedBox.expand(key: Key('empty-background')),
                        ),
                      ),
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('empty-background')), findsOneWidget);

      await tester.dragFrom(const Offset(10, 300), const Offset(300, 0));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('empty-background')), findsNothing);
    });
  });
}
