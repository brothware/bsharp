import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:bsharp/wear/screens/wear_settings_tile.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:bsharp/wear/widgets/wear_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/credential_storage_test.dart';

class _FakeSyncStatusNotifier extends SyncStatusNotifier {
  _FakeSyncStatusNotifier(this._initial);

  final SyncStatus _initial;

  @override
  SyncStatus build() => _initial;
}

Future<Widget> _buildApp({List<Object> extraOverrides = const []}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final storage = CredentialStorage(store: FakeKeyValueStore());
  return ProviderScope(
    overrides: [
      credentialStorageProvider.overrideWithValue(storage),
      sharedPreferencesProvider.overrideWithValue(prefs),
      wearScreenShapeProvider.overrideWith((_) => WearScreenShape.rectangular),
      ...extraOverrides.cast(),
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

    testWidgets('tapping logout shows a confirmation screen', (tester) async {
      await tester.pumpWidget(await _buildApp());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Are you sure you want to log out? Saved data will be deleted.',
        ),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('cancel dismisses the logout confirmation screen', (
      tester,
    ) async {
      await tester.pumpWidget(await _buildApp());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(WearSettingsTile), findsOneWidget);
      expect(
        find.text(
          'Are you sure you want to log out? Saved data will be deleted.',
        ),
        findsNothing,
      );
    });

    testWidgets(
      'in child mode only shows active item, hides sync/about/logout',
      (tester) async {
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
        await tester.pump();

        expect(find.text('Child mode active'), findsOneWidget);
        expect(find.byIcon(Icons.sync), findsNothing);
        expect(find.byIcon(Icons.info_outline), findsNothing);
        expect(find.byIcon(Icons.logout), findsNothing);
      },
    );

    testWidgets('parent mode shows all items', (tester) async {
      await tester.pumpWidget(await _buildApp());
      await tester.pump();

      expect(find.byIcon(Icons.brightness_6), findsOneWidget);
      expect(find.byIcon(Icons.sync), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('tapping theme opens a theme selection screen', (
      tester,
    ) async {
      await tester.pumpWidget(await _buildApp());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.brightness_6));
      await tester.pumpAndSettle();

      expect(find.text('System'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.byIcon(Icons.brightness_auto), findsOneWidget);
      expect(find.byIcon(Icons.light_mode), findsOneWidget);
      expect(find.byIcon(Icons.dark_mode), findsOneWidget);
    });

    testWidgets('selecting a theme mode pops the selection screen', (
      tester,
    ) async {
      await tester.pumpWidget(await _buildApp());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.brightness_6));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(find.text('System'), findsNothing);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets(
      'syncing status stays under the sync row and inside the round '
      'safe area at 227dp',
      (tester) async {
        tester.view.physicalSize = const Size(227, 227);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final storage = CredentialStorage(store: FakeKeyValueStore());

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              credentialStorageProvider.overrideWithValue(storage),
              sharedPreferencesProvider.overrideWithValue(prefs),
              wearScreenShapeProvider.overrideWith(
                (_) => WearScreenShape.round,
              ),
              syncStatusProvider.overrideWith(
                () => _FakeSyncStatusNotifier(SyncStatus.syncing),
              ),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: WearDisplayScope(
                  display: WearDisplay(
                    shape: WearScreenShape.round,
                    sizeDp: Size(227, 227),
                  ),
                  child: WearSettingsTile(),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final syncLabelRect = tester.getRect(find.byIcon(Icons.sync));
        final statusRect = tester.getRect(
          find.byType(CircularProgressIndicator),
        );

        expect(
          statusRect.top,
          greaterThanOrEqualTo(syncLabelRect.bottom),
          reason:
              'status indicator should sit below the Sync row, not '
              'beside it',
        );
        expect(statusRect.right, lessThanOrEqualTo(227));
        expect(statusRect.left, greaterThanOrEqualTo(0));
      },
    );
  });
}
