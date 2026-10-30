import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/child_mode_provider.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/wear/screens/wear_pin_entry.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:bsharp/wear/widgets/wear_pin_dial.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../data/credential_storage_test.dart';

Finder _filledDots() => find.byWidgetPredicate(
  (widget) => widget is WearPinDot && widget.isFilled,
);

void main() {
  group('WearPinEntry', () {
    testWidgets('the heading stays inside a 192dp round screen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(192, 192);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.binding.defaultBinaryMessenger.setMockStreamHandler(
        const EventChannel('wear_os_scrollbar/rotary'),
        MockStreamHandler.inline(onListen: (_, _) {}),
      );
      final storage = CredentialStorage(store: FakeKeyValueStore());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            credentialStorageProvider.overrideWithValue(storage),
            wearScreenShapeProvider.overrideWith((_) => WearScreenShape.round),
          ],
          child: const MaterialApp(home: WearPinEntry()),
        ),
      );
      await tester.pump();

      final paragraph = tester.renderObject<RenderParagraph>(
        find.text('Enter parent PIN'),
      );
      final origin = paragraph.localToGlobal(Offset.zero);
      final lines = paragraph.getBoxesForSelection(
        TextSelection(
          baseOffset: 0,
          extentOffset: paragraph.text.toPlainText().length,
        ),
      );
      const centre = Offset(96, 96);
      for (final line in lines) {
        for (final corner in [
          Offset(line.left, line.top),
          Offset(line.right, line.top),
        ]) {
          expect(
            (origin + corner - centre).distance,
            lessThanOrEqualTo(96),
            reason: 'the heading corner ${origin + corner} is off the glass',
          );
        }
      }
    });

    testWidgets('renders title and keypad', (tester) async {
      final storage = CredentialStorage(store: FakeKeyValueStore());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            credentialStorageProvider.overrideWithValue(storage),
            wearScreenShapeProvider.overrideWith(
              (_) => WearScreenShape.rectangular,
            ),
          ],
          child: const MaterialApp(home: WearPinEntry()),
        ),
      );
      await tester.pump();

      expect(find.text('Enter parent PIN'), findsOneWidget);
      for (final digit in ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']) {
        expect(find.text(digit), findsOneWidget);
      }
    });

    testWidgets('shows the dots once a digit is entered', (tester) async {
      final storage = CredentialStorage(store: FakeKeyValueStore());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            credentialStorageProvider.overrideWithValue(storage),
            wearScreenShapeProvider.overrideWith(
              (_) => WearScreenShape.rectangular,
            ),
          ],
          child: const MaterialApp(home: WearPinEntry()),
        ),
      );
      await tester.pump();

      expect(find.byType(WearPinDot), findsNothing);

      await tester.tap(find.text('1'));
      await tester.pump();

      expect(find.byType(WearPinDot), findsNWidgets(4));
      expect(_filledDots(), findsOneWidget);
    });

    testWidgets('shows error on wrong PIN', (tester) async {
      final fakeSecure = FakeKeyValueStore();
      await fakeSecure.write(key: 'child_mode_pin', value: '1234');
      await fakeSecure.write(key: 'child_mode_active', value: 'true');
      final storage = CredentialStorage(store: fakeSecure);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            credentialStorageProvider.overrideWithValue(storage),
            wearScreenShapeProvider.overrideWith(
              (_) => WearScreenShape.rectangular,
            ),
          ],
          child: const MaterialApp(home: WearPinEntry()),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('0'));
      await tester.tap(find.text('0'));
      await tester.tap(find.text('0'));
      await tester.tap(find.text('0'));
      await tester.pump();

      expect(find.text('Attempts remaining: 4'), findsOneWidget);
    });

    testWidgets('shows decreasing attempts on repeated wrong PINs', (
      tester,
    ) async {
      final fakeSecure = FakeKeyValueStore();
      await fakeSecure.write(key: 'child_mode_pin', value: '1234');
      await fakeSecure.write(key: 'child_mode_active', value: 'true');
      final storage = CredentialStorage(store: fakeSecure);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            credentialStorageProvider.overrideWithValue(storage),
            wearScreenShapeProvider.overrideWith(
              (_) => WearScreenShape.rectangular,
            ),
          ],
          child: const MaterialApp(home: WearPinEntry()),
        ),
      );
      await tester.pump();
      await tester.pump();

      for (final digit in ['0', '0', '0', '0']) {
        await tester.tap(find.text(digit));
      }
      await tester.pump();
      expect(find.text('Attempts remaining: 4'), findsOneWidget);

      for (final digit in ['0', '0', '0', '0']) {
        await tester.tap(find.text(digit));
      }
      await tester.pump();
      expect(find.text('Attempts remaining: 3'), findsOneWidget);
    });

    testWidgets('shows locked state after max attempts', (tester) async {
      final lockedUntil = DateTime.now().add(const Duration(minutes: 5));
      final fakeSecure = FakeKeyValueStore();
      await fakeSecure.write(key: 'child_mode_pin', value: '1234');
      await fakeSecure.write(key: 'child_mode_active', value: 'true');
      await fakeSecure.write(
        key: 'child_mode_failed_attempts',
        value: '${ChildModeNotifier.maxAttempts}',
      );
      await fakeSecure.write(
        key: 'child_mode_locked_until',
        value: lockedUntil.toIso8601String(),
      );
      final storage = CredentialStorage(store: fakeSecure);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            credentialStorageProvider.overrideWithValue(storage),
            wearScreenShapeProvider.overrideWith(
              (_) => WearScreenShape.rectangular,
            ),
          ],
          child: const MaterialApp(home: WearPinEntry()),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Locked'), findsOneWidget);
      expect(find.text('Try again in 5 minutes'), findsOneWidget);
      expect(find.byIcon(Icons.lock_clock), findsOneWidget);
    });

    testWidgets('delete button removes last entered digit', (tester) async {
      final storage = CredentialStorage(store: FakeKeyValueStore());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            credentialStorageProvider.overrideWithValue(storage),
            wearScreenShapeProvider.overrideWith(
              (_) => WearScreenShape.rectangular,
            ),
          ],
          child: const MaterialApp(home: WearPinEntry()),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('1'));
      await tester.tap(find.text('2'));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pump();

      expect(_filledDots(), findsOneWidget);
    });
  });
}
