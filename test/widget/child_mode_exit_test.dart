import 'dart:convert';

import 'package:bsharp/app/account_providers.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/child_mode_provider.dart';
import 'package:bsharp/app/router.dart';
import 'package:bsharp/data/data_sources/local/account_storage.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/domain/entities/provider_account.dart';
import 'package:bsharp/presentation/child_mode/screens/child_mode_config_screen.dart';
import 'package:bsharp/presentation/child_mode/screens/pin_entry_screen.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../unit/data/credential_storage_test.dart';

const _pin = '1234';

Future<AccountStorage> _accountStorage() async {
  final storage = AccountStorage(store: FakeKeyValueStore());
  await storage.saveAccounts([
    const ProviderAccount(
      id: 'a1',
      providerType: 'mobireg',
      slug: 'osm-wroclaw',
      login: 'login1',
      students: [AccountStudent(id: 1, name: 'Jan', surname: 'Kowalski')],
    ),
  ]);
  await storage.saveActiveSelection(
    const ActiveSelection(accountId: 'a1', studentId: 1),
  );
  return storage;
}

Future<CredentialStorage> _childModeOn({required bool settingsVisible}) async {
  final store = FakeKeyValueStore();
  await store.write(key: 'child_mode_pin', value: _pin);
  await store.write(key: 'child_mode_active', value: 'true');
  await store.write(
    key: 'child_mode_config',
    value: jsonEncode(
      ChildModeConfig(settingsVisible: settingsVisible).toJson(),
    ),
  );
  return CredentialStorage(store: store);
}

Future<ProviderContainer> _pumpApp(
  WidgetTester tester, {
  required CredentialStorage credentials,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final accounts = await _accountStorage();
  final router = createRouter(authState: AuthState.authenticated);
  late ProviderContainer container;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        accountStorageProvider.overrideWithValue(accounts),
        credentialStorageProvider.overrideWithValue(credentials),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          container = ProviderScope.containerOf(context);
          return MaterialApp.router(routerConfig: router);
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> _enterPin(WidgetTester tester, String pin) async {
  for (final digit in pin.split('')) {
    await tester.tap(find.text(digit));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  group('leaving child mode on the phone', () {
    testWidgets('Settings stays reachable while the child cannot see it', (
      tester,
    ) async {
      final container = await _pumpApp(
        tester,
        credentials: await _childModeOn(settingsVisible: false),
      );
      expect(container.read(childModeProvider).isChildMode, isTrue);

      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Child mode active'), findsOneWidget);
      expect(find.text('Appearance'), findsNothing);
    });

    testWidgets('the parent PIN leaves child mode from Settings', (
      tester,
    ) async {
      final container = await _pumpApp(
        tester,
        credentials: await _childModeOn(settingsVisible: false),
      );

      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Child mode active'));
      await tester.pumpAndSettle();
      expect(find.byType(PinEntryScreen), findsOneWidget);

      await _enterPin(tester, _pin);

      expect(container.read(childModeProvider).isParentMode, isTrue);
      expect(find.text('Appearance'), findsOneWidget);
    });

    testWidgets('a wrong PIN keeps child mode on', (tester) async {
      final container = await _pumpApp(
        tester,
        credentials: await _childModeOn(settingsVisible: false),
      );

      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Child mode active'));
      await tester.pumpAndSettle();
      await _enterPin(tester, '9999');

      expect(container.read(childModeProvider).isChildMode, isTrue);
      expect(find.text('Invalid PIN'), findsOneWidget);
    });

    testWidgets('Settings the child may see still offers the way out', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        credentials: await _childModeOn(settingsVisible: true),
      );

      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Child mode active'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
    });

    testWidgets('child mode setup asks for the parent PIN first', (
      tester,
    ) async {
      final container = await _pumpApp(
        tester,
        credentials: await _childModeOn(settingsVisible: true),
      );

      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Child mode configuration'),
        300,
      );
      await tester.tap(find.text('Child mode configuration'));
      await tester.pumpAndSettle();

      expect(find.byType(PinEntryScreen), findsOneWidget);
      expect(find.byType(ChildModeConfigScreen), findsNothing);

      await _enterPin(tester, _pin);

      expect(find.byType(ChildModeConfigScreen), findsOneWidget);
      expect(container.read(childModeProvider).isParentMode, isTrue);
    });

    testWidgets('a wrong PIN keeps child mode setup closed', (tester) async {
      await _pumpApp(
        tester,
        credentials: await _childModeOn(settingsVisible: true),
      );

      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Child mode configuration'),
        300,
      );
      await tester.tap(find.text('Child mode configuration'));
      await tester.pumpAndSettle();
      await _enterPin(tester, '9999');
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(ChildModeConfigScreen), findsNothing);
    });
  });
}
