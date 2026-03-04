import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/wear/screens/wear_pin_setup_screen.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../data/credential_storage_test.dart';

Widget _buildApp({List<Override> overrides = const []}) {
  final storage = CredentialStorage(store: FakeKeyValueStore());
  return ProviderScope(
    overrides: [
      credentialStorageProvider.overrideWithValue(storage),
      wearScreenShapeProvider.overrideWith((_) => WearScreenShape.rectangular),
      ...overrides,
    ],
    child: const MaterialApp(home: WearPinSetupScreen()),
  );
}

void main() {
  group('WearPinSetupScreen', () {
    testWidgets('renders create PIN title and keypad', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      expect(find.text('Create PIN'), findsOneWidget);
      for (final digit in ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']) {
        expect(find.text(digit), findsOneWidget);
      }
      expect(find.byIcon(Icons.backspace_outlined), findsOneWidget);
    });

    testWidgets('switches to confirm step after 4 digits', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      await tester.tap(find.text('1'));
      await tester.tap(find.text('2'));
      await tester.tap(find.text('3'));
      await tester.tap(find.text('4'));
      await tester.pump();

      expect(find.text('Confirm PIN'), findsOneWidget);
    });

    testWidgets('shows mismatch error on wrong confirm', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      await tester.tap(find.text('1'));
      await tester.tap(find.text('2'));
      await tester.tap(find.text('3'));
      await tester.tap(find.text('4'));
      await tester.pump();

      await tester.tap(find.text('5'));
      await tester.tap(find.text('6'));
      await tester.tap(find.text('7'));
      await tester.tap(find.text('8'));
      await tester.pump();

      expect(find.text('PIN does not match, try again'), findsOneWidget);
      expect(find.text('Create PIN'), findsOneWidget);
    });

    testWidgets('successful setup pops with true', (tester) async {
      var popResult = false;
      final storage = CredentialStorage(store: FakeKeyValueStore());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            credentialStorageProvider.overrideWithValue(storage),
            wearScreenShapeProvider.overrideWith(
              (_) => WearScreenShape.rectangular,
            ),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute<bool>(
                        builder: (_) => const WearPinSetupScreen(),
                      ),
                    );
                    popResult = result ?? false;
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('1'));
      await tester.tap(find.text('2'));
      await tester.tap(find.text('3'));
      await tester.tap(find.text('4'));
      await tester.pump();

      await tester.tap(find.text('1'));
      await tester.tap(find.text('2'));
      await tester.tap(find.text('3'));
      await tester.tap(find.text('4'));
      await tester.pumpAndSettle();

      expect(popResult, isTrue);
    });

    testWidgets('delete button removes last digit', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      await tester.tap(find.text('1'));
      await tester.tap(find.text('2'));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pump();

      expect(find.text('Create PIN'), findsOneWidget);
    });
  });
}
