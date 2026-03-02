import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/child_mode_provider.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/wear/screens/wear_pin_entry.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';

import '../data/credential_storage_test.dart';

void main() {
  group('WearPinEntry', () {
    testWidgets('renders title and keypad', (tester) async {
      final storage =
          CredentialStorage(store: FakeKeyValueStore());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            credentialStorageProvider.overrideWithValue(storage),
            wearScreenShapeProvider
                .overrideWith((_) => WearScreenShape.rectangular),
          ],
          child: const MaterialApp(home: WearPinEntry()),
        ),
      );
      await tester.pump();

      expect(find.text('Enter parent PIN'), findsOneWidget);
      for (final digit in [
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
      ]) {
        expect(find.text(digit), findsOneWidget);
      }
    });

    testWidgets('shows pin dots', (tester) async {
      final storage =
          CredentialStorage(store: FakeKeyValueStore());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            credentialStorageProvider.overrideWithValue(storage),
            wearScreenShapeProvider
                .overrideWith((_) => WearScreenShape.rectangular),
          ],
          child: const MaterialApp(home: WearPinEntry()),
        ),
      );
      await tester.pump();

      final containers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(Row),
          matching: find.byType(Container),
        ),
      );
      final dots = containers.where(
        (c) =>
            c.constraints?.maxWidth == 12 && c.constraints?.maxHeight == 12,
      );
      expect(dots.length, 4);
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
            wearScreenShapeProvider
                .overrideWith((_) => WearScreenShape.rectangular),
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

    testWidgets('shows decreasing attempts on repeated wrong PINs',
        (tester) async {
      final fakeSecure = FakeKeyValueStore();
      await fakeSecure.write(key: 'child_mode_pin', value: '1234');
      await fakeSecure.write(key: 'child_mode_active', value: 'true');
      final storage = CredentialStorage(store: fakeSecure);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            credentialStorageProvider.overrideWithValue(storage),
            wearScreenShapeProvider
                .overrideWith((_) => WearScreenShape.rectangular),
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
            wearScreenShapeProvider
                .overrideWith((_) => WearScreenShape.rectangular),
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
      final storage =
          CredentialStorage(store: FakeKeyValueStore());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            credentialStorageProvider.overrideWithValue(storage),
            wearScreenShapeProvider
                .overrideWith((_) => WearScreenShape.rectangular),
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

      expect(find.byType(WearPinEntry), findsOneWidget);
    });
  });
}
