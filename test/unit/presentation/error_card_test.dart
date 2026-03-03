import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/presentation/common/widgets/error_card.dart';

void main() {
  group('ErrorCard', () {
    testWidgets('shows error message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ErrorCard(failure: NoConnection())),
        ),
      );

      expect(find.textContaining('connection'), findsOneWidget);
    });

    testWidgets('shows icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ErrorCard(failure: NoConnection())),
        ),
      );

      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    });

    testWidgets('shows retry button for retryable failure', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorCard(failure: const NoConnection(), onRetry: () {}),
          ),
        ),
      );

      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('hides retry button for non-retryable failure', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorCard(
              failure: const InvalidCredentials(),
              onRetry: () {},
            ),
          ),
        ),
      );

      expect(find.text('Try again'), findsNothing);
    });

    testWidgets('retry callback is invoked on tap', (tester) async {
      var retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorCard(
              failure: const NoConnection(),
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Try again'));
      expect(retried, isTrue);
    });

    testWidgets('shows lock icon for auth failures', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ErrorCard(failure: InvalidCredentials())),
        ),
      );

      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('shows generic icon for unknown failure', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ErrorCard(failure: UnknownFailure())),
        ),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });
}
