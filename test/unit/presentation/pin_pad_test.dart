import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bsharp/presentation/child_mode/widgets/pin_pad.dart';

void main() {
  Widget buildPinPad({
    void Function(String)? onComplete,
    int pinLength = 4,
    String? errorMessage,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: PinPad(
          onComplete: onComplete ?? (_) {},
          pinLength: pinLength,
          errorMessage: errorMessage,
        ),
      ),
    );
  }

  group('PinPad', () {
    testWidgets('renders title and keypad', (tester) async {
      await tester.pumpWidget(buildPinPad());

      expect(find.text('Enter PIN'), findsOneWidget);
      for (final digit in ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']) {
        expect(find.text(digit), findsOneWidget);
      }
      expect(find.byIcon(Icons.backspace_outlined), findsOneWidget);
    });

    testWidgets('renders custom title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinPad(
              title: 'Create PIN',
              onComplete: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Create PIN'), findsOneWidget);
    });

    testWidgets('displays error message', (tester) async {
      await tester.pumpWidget(buildPinPad(errorMessage: 'Invalid PIN'));

      expect(find.text('Invalid PIN'), findsOneWidget);
    });

    testWidgets('calls onComplete after entering full PIN', (tester) async {
      String? enteredPin;
      await tester.pumpWidget(buildPinPad(onComplete: (pin) => enteredPin = pin));

      await tester.tap(find.text('1'));
      await tester.tap(find.text('2'));
      await tester.tap(find.text('3'));
      await tester.tap(find.text('4'));
      await tester.pump();

      expect(enteredPin, '1234');
    });

    testWidgets('does not call onComplete before PIN is full', (tester) async {
      String? enteredPin;
      await tester.pumpWidget(buildPinPad(onComplete: (pin) => enteredPin = pin));

      await tester.tap(find.text('1'));
      await tester.tap(find.text('2'));
      await tester.tap(find.text('3'));
      await tester.pump();

      expect(enteredPin, isNull);
    });

    testWidgets('delete removes last digit', (tester) async {
      String? enteredPin;
      await tester.pumpWidget(buildPinPad(onComplete: (pin) => enteredPin = pin));

      await tester.tap(find.text('1'));
      await tester.tap(find.text('2'));
      await tester.tap(find.text('3'));
      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.tap(find.text('5'));
      await tester.tap(find.text('6'));
      await tester.pump();

      expect(enteredPin, '1256');
    });

    testWidgets('renders correct number of pin dots', (tester) async {
      await tester.pumpWidget(buildPinPad(pinLength: 6));
      await tester.pump();

      final containers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(Row),
          matching: find.byType(Container),
        ),
      );
      final dots = containers.where(
        (c) =>
            c.constraints?.maxWidth == 16 && c.constraints?.maxHeight == 16,
      );
      expect(dots.length, 6);
    });

    testWidgets('shake clears PIN and animates', (tester) async {
      final key = GlobalKey<PinPadState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinPad(
              key: key,
              onComplete: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('1'));
      await tester.tap(find.text('2'));
      await tester.pump();

      key.currentState!.shake();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // After shake, PIN should be cleared - tapping 2 more digits should
      // not complete a 4-digit PIN
      String? enteredPin;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinPad(
              key: key,
              onComplete: (pin) => enteredPin = pin,
            ),
          ),
        ),
      );
      await tester.tap(find.text('3'));
      await tester.tap(find.text('4'));
      await tester.pump();

      expect(enteredPin, isNull);
    });
  });
}
