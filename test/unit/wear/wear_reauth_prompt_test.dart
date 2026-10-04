import 'package:bsharp/app/account_providers.dart';
import 'package:bsharp/app/data_provider_registry.dart';
import 'package:bsharp/app/reauth_provider.dart';
import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/data/data_sources/local/account_storage.dart';
import 'package:bsharp/data/providers/demo/demo_data_provider.dart';
import 'package:bsharp/domain/entities/provider_account.dart';
import 'package:bsharp/domain/school_data_provider.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:bsharp/wear/screens/wear_reauth_screen.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/credential_storage_test.dart';

const _legacyAccount = ProviderAccount(
  id: 'a1',
  providerType: 'mobireg',
  slug: 'sp1',
  login: 'p',
  students: [AccountStudent(id: 6339, name: 'Maria', surname: 'Kowalska')],
);

class _ProbingProvider extends DemoDataProvider {
  _ProbingProvider({required this.accepts});

  final bool accepts;

  @override
  String get id => 'mobireg';

  @override
  bool get requiresCredentials => true;

  @override
  Future<Result<AccountProbe>> probeAccount({
    required String school,
    required String login,
    required String password,
  }) async => accepts
      ? const Result.success(AccountProbe(schoolName: 'S', students: []))
      : const Result.failure(InvalidCredentials());
}

Future<(ProviderContainer, AccountStorage)> _container(
  _ProbingProvider provider,
) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final storage = AccountStorage(store: FakeKeyValueStore());
  await storage.saveAccounts([_legacyAccount]);
  await storage.saveActiveSelection(
    const ActiveSelection(accountId: 'a1', studentId: 6339),
  );
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      accountStorageProvider.overrideWithValue(storage),
      activeDataProviderProvider.overrideWithBuild((ref, _) => provider),
      wearScreenShapeProvider.overrideWith((_) => WearScreenShape.rectangular),
    ],
  );
  addTearDown(container.dispose);
  await container.read(providerAccountsProvider.future);
  await container.read(activeSelectionProvider.future);
  return (container, storage);
}

Widget _app(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(
      home: WearReauthPrompt(child: Scaffold(body: Text('Home'))),
    ),
  );
}

Future<void> _submit(WidgetTester tester, String password) async {
  await tester.enterText(find.byType(TextField), password);
  await tester.tap(find.text('Log in'));
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a pre-switch account is asked for its password', (
    tester,
  ) async {
    final (container, _) = (await tester.runAsync(
      () => _container(_ProbingProvider(accepts: true)),
    ))!;
    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();
    expect(find.text('Sign in again'), findsNothing);

    container.read(reauthRequiredProvider.notifier).value = true;
    await tester.pumpAndSettle();

    expect(find.text('Sign in again'), findsOneWidget);
    expect(
      find.text(
        'Your password is needed to load messages and other portal data. '
        'Please enter it again.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a rejected password stays on the screen with an error', (
    tester,
  ) async {
    final (container, storage) = (await tester.runAsync(
      () => _container(_ProbingProvider(accepts: false)),
    ))!;
    container.read(reauthRequiredProvider.notifier).value = true;
    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    await _submit(tester, 'wrong');

    expect(find.text('Invalid credentials'), findsOneWidget);
    final stored = (await tester.runAsync(storage.getAccounts))!;
    expect(stored.single.password, isEmpty);
  });

  testWidgets(
    'an accepted password is saved and returns home',
    (tester) async {
      tester.binding.defaultBinaryMessenger.setMockStreamHandler(
        const EventChannel('wear_os_scrollbar/rotary'),
        MockStreamHandler.inline(onListen: (_, _) {}),
      );
      final (container, storage) = (await tester.runAsync(
        () => _container(_ProbingProvider(accepts: true)),
      ))!;
      container.read(reauthRequiredProvider.notifier).value = true;
      await tester.pumpWidget(_app(container));
      await tester.pumpAndSettle();

      await _submit(tester, 'new');
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(minutes: 1));

      expect(find.text('Sign in again'), findsNothing);
      expect(find.text('Home'), findsOneWidget);
      final stored = (await tester.runAsync(storage.getAccounts))!;
      expect(stored.single.password, 'new');
      expect(container.read(reauthRequiredProvider), isFalse);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );
}
