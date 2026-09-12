import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:bsharp/wear/widgets/wear_confirmation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _longQuestion =
    'Are you sure you want to log out of this account right now? '
    'All locally saved data for this student will be permanently '
    'deleted from this watch and cannot be recovered.';

Future<bool?> _pumpAndOpen(
  WidgetTester tester,
  WearScreenShape shape, {
  bool isDestructive = false,
  Size? viewSize,
}) async {
  if (viewSize != null) {
    tester.view.physicalSize = viewSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  bool? result;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [wearScreenShapeProvider.overrideWith((_) => shape)],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await showWearConfirmation(
                    context,
                    icon: Icons.logout,
                    question: _longQuestion,
                    confirmLabel: 'Log out',
                    isDestructive: isDestructive,
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  group('showWearConfirmation', () {
    testWidgets('shows the full question text without ellipsis', (
      tester,
    ) async {
      await _pumpAndOpen(tester, WearScreenShape.rectangular);

      final textWidget = tester.widget<Text>(find.text(_longQuestion));
      expect(textWidget.overflow, isNot(TextOverflow.ellipsis));
      expect(tester.takeException(), isNull);
    });

    testWidgets('both buttons are at least 48dp tall on rectangular', (
      tester,
    ) async {
      await _pumpAndOpen(tester, WearScreenShape.rectangular);

      final confirmButtonSize = tester.getSize(
        find.ancestor(
          of: find.text('Log out').last,
          matching: find.byType(FilledButton),
        ),
      );
      final cancelButtonSize = tester.getSize(
        find.ancestor(
          of: find.text('Cancel'),
          matching: find.byType(OutlinedButton),
        ),
      );
      expect(confirmButtonSize.height, greaterThanOrEqualTo(48));
      expect(cancelButtonSize.height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
    });

    testWidgets('no overflow on round shape', (tester) async {
      await _pumpAndOpen(tester, WearScreenShape.round);

      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'both buttons are fully visible without scrolling on a 227dp round '
      'watch',
      (tester) async {
        await _pumpAndOpen(
          tester,
          WearScreenShape.round,
          isDestructive: true,
          viewSize: const Size(227, 227),
        );

        final viewport = Offset.zero & const Size(227, 227);
        final confirmRect = tester.getRect(
          find.ancestor(
            of: find.text('Log out').last,
            matching: find.byType(FilledButton),
          ),
        );
        final cancelRect = tester.getRect(
          find.ancestor(
            of: find.text('Cancel'),
            matching: find.byType(OutlinedButton),
          ),
        );

        expect(viewport.contains(confirmRect.topLeft), isTrue);
        expect(viewport.contains(confirmRect.bottomRight), isTrue);
        expect(viewport.contains(cancelRect.topLeft), isTrue);
        expect(viewport.contains(cancelRect.bottomRight), isTrue);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'both buttons are fully visible without scrolling on a 201x238dp '
      'rectangular watch',
      (tester) async {
        await _pumpAndOpen(
          tester,
          WearScreenShape.rectangular,
          isDestructive: true,
          viewSize: const Size(201, 238),
        );

        final viewport = Offset.zero & const Size(201, 238);
        final confirmRect = tester.getRect(
          find.ancestor(
            of: find.text('Log out').last,
            matching: find.byType(FilledButton),
          ),
        );
        final cancelRect = tester.getRect(
          find.ancestor(
            of: find.text('Cancel'),
            matching: find.byType(OutlinedButton),
          ),
        );

        expect(viewport.contains(confirmRect.topLeft), isTrue);
        expect(viewport.contains(confirmRect.bottomRight), isTrue);
        expect(viewport.contains(cancelRect.topLeft), isTrue);
        expect(viewport.contains(cancelRect.bottomRight), isTrue);
        expect(confirmRect.height, greaterThanOrEqualTo(48));
        expect(cancelRect.height, greaterThanOrEqualTo(48));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('returns true on confirm', (tester) async {
      bool? result;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            wearScreenShapeProvider.overrideWith(
              (_) => WearScreenShape.rectangular,
            ),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    result = await showWearConfirmation(
                      context,
                      icon: Icons.logout,
                      question: 'Confirm?',
                      confirmLabel: 'Yes',
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('returns false on cancel', (tester) async {
      bool? result;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            wearScreenShapeProvider.overrideWith(
              (_) => WearScreenShape.rectangular,
            ),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    result = await showWearConfirmation(
                      context,
                      icon: Icons.logout,
                      question: 'Confirm?',
                      confirmLabel: 'Yes',
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('returns false when dismissed via back navigation', (
      tester,
    ) async {
      bool? result;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            wearScreenShapeProvider.overrideWith(
              (_) => WearScreenShape.rectangular,
            ),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    result = await showWearConfirmation(
                      context,
                      icon: Icons.logout,
                      question: 'Confirm?',
                      confirmLabel: 'Yes',
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });
  });
}
