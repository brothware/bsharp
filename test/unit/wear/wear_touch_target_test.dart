import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:bsharp/wear/screens/wear_child_mode_screen.dart';
import 'package:bsharp/wear/screens/wear_language_screen.dart';
import 'package:bsharp/wear/screens/wear_notes_detail_screen.dart';
import 'package:bsharp/wear/screens/wear_settings_tile.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:bsharp/wear/widgets/wear_compact_keypad.dart';
import 'package:bsharp/wear/widgets/wear_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/credential_storage_test.dart';

const _minTouchTarget = 48.0;

void _expectAllAtLeastMinTouchTarget(WidgetTester tester, Finder finder) {
  final elements = finder.evaluate();
  expect(elements, isNotEmpty);
  for (final element in elements) {
    final size = tester.getSize(find.byWidget(element.widget));
    final smallerAxis = size.width < size.height ? size.width : size.height;
    expect(
      smallerAxis,
      greaterThanOrEqualTo(_minTouchTarget),
      reason: '${element.widget} is $size, smaller than 48dp',
    );
  }
}

void main() {
  group('Wear touch targets', () {
    testWidgets('PIN keypad keys are at least 48dp', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WearCompactKeypad(onKeyTap: (_) {})),
        ),
      );
      await tester.pump();

      _expectAllAtLeastMinTouchTarget(tester, find.byType(InkWell));
    });

    testWidgets('settings rows are at least 48dp', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = CredentialStorage(store: FakeKeyValueStore());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            credentialStorageProvider.overrideWithValue(storage),
            wearScreenShapeProvider.overrideWith(
              (_) => WearScreenShape.rectangular,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: WearDisplayScope(
                display: WearDisplay(
                  shape: WearScreenShape.rectangular,
                  sizeDp: Size(400, 400),
                ),
                child: WearSettingsTile(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      _expectAllAtLeastMinTouchTarget(tester, find.byType(InkWell));
    });

    testWidgets('child mode items and toggles are at least 48dp', (
      tester,
    ) async {
      final fakeSecure = FakeKeyValueStore();
      await fakeSecure.write(key: 'child_mode_pin', value: '1234');
      final storage = CredentialStorage(store: fakeSecure);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            credentialStorageProvider.overrideWithValue(storage),
            wearScreenShapeProvider.overrideWith(
              (_) => WearScreenShape.rectangular,
            ),
          ],
          child: const MaterialApp(home: WearChildModeScreen()),
        ),
      );
      await tester.pump();
      await tester.pump();

      _expectAllAtLeastMinTouchTarget(tester, find.byType(InkWell));
      _expectAllAtLeastMinTouchTarget(tester, find.byType(Switch));
    });

    testWidgets('language rows are at least 48dp', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = CredentialStorage(store: FakeKeyValueStore());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            credentialStorageProvider.overrideWithValue(storage),
            wearScreenShapeProvider.overrideWith(
              (_) => WearScreenShape.rectangular,
            ),
          ],
          child: const MaterialApp(home: WearLanguageScreen()),
        ),
      );
      await tester.pump();

      _expectAllAtLeastMinTouchTarget(tester, find.byType(InkWell));
    });

    testWidgets('notes tab buttons are at least 48dp', (tester) async {
      final storage = CredentialStorage(store: FakeKeyValueStore());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            credentialStorageProvider.overrideWithValue(storage),
            wearScreenShapeProvider.overrideWith(
              (_) => WearScreenShape.rectangular,
            ),
          ],
          child: const MaterialApp(home: WearNotesDetailScreen()),
        ),
      );
      await tester.pump();

      _expectAllAtLeastMinTouchTarget(tester, find.byType(GestureDetector));
    });
  });
}
