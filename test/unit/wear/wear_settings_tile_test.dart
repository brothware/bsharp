import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/child_mode_provider.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:bsharp/wear/screens/wear_settings_tile.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/credential_storage_test.dart';

Future<Widget> _buildApp({List<Override> overrides = const []}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final storage = CredentialStorage(store: FakeKeyValueStore());
  return ProviderScope(
    overrides: [
      credentialStorageProvider.overrideWithValue(storage),
      sharedPreferencesProvider.overrideWithValue(prefs),
      wearScreenShapeProvider.overrideWith((_) => WearScreenShape.rectangular),
      ...overrides,
    ],
    child: const MaterialApp(home: Scaffold(body: WearSettingsTile())),
  );
}

void main() {
  group('WearSettingsTile', () {
    testWidgets('renders logout button with logout icon', (tester) async {
      await tester.pumpWidget(await _buildApp());
      await tester.pump();

      expect(find.byIcon(Icons.logout), findsOneWidget);
      expect(find.text('Log out'), findsOneWidget);
    });

    testWidgets('renders child mode entry in parent mode', (tester) async {
      await tester.pumpWidget(await _buildApp());
      await tester.pump();

      expect(find.text('Child mode'), findsOneWidget);
      expect(find.byIcon(Icons.child_care), findsOneWidget);
    });

    testWidgets('tapping logout shows confirmation dialog', (tester) async {
      await tester.pumpWidget(await _buildApp());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.text(
          'Are you sure you want to log out? Saved data will be deleted.',
        ),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('cancel dismisses logout dialog', (tester) async {
      await tester.pumpWidget(await _buildApp());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('in child mode only shows active item, hides sync/about/logout',
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
          child: const MaterialApp(home: Scaffold(body: WearSettingsTile())),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Child mode active'), findsOneWidget);
      expect(find.byIcon(Icons.sync), findsNothing);
      expect(find.byIcon(Icons.info_outline), findsNothing);
      expect(find.byIcon(Icons.logout), findsNothing);
    });

    testWidgets('parent mode shows all items', (tester) async {
      await tester.pumpWidget(await _buildApp());
      await tester.pump();

      expect(find.byIcon(Icons.brightness_6), findsOneWidget);
      expect(find.byIcon(Icons.sync), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('tapping theme opens theme dialog', (tester) async {
      await tester.pumpWidget(await _buildApp());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.brightness_6));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.byIcon(Icons.brightness_auto), findsOneWidget);
      expect(find.byIcon(Icons.light_mode), findsOneWidget);
      expect(find.byIcon(Icons.dark_mode), findsOneWidget);
    });

    testWidgets('selecting theme mode dismisses dialog', (tester) async {
      await tester.pumpWidget(await _buildApp());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.brightness_6));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
    });
  });
}
