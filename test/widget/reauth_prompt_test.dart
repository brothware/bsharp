import 'package:bsharp/app/account_providers.dart';
import 'package:bsharp/app/data_provider_registry.dart';
import 'package:bsharp/app/reauth_provider.dart';
import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/data/data_sources/local/account_storage.dart';
import 'package:bsharp/data/providers/demo/demo_data_provider.dart';
import 'package:bsharp/domain/entities/provider_account.dart';
import 'package:bsharp/domain/school_data_provider.dart';
import 'package:bsharp/presentation/auth/widgets/reauth_dialog.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../unit/data/credential_storage_test.dart';

const _account = ProviderAccount(
  id: 'a1',
  providerType: 'mobireg',
  slug: 'sp1',
  login: 'p',
  students: [AccountStudent(id: 6339, name: 'Maria', surname: 'Kowalska')],
);

class _ProbingProvider extends DemoDataProvider {
  _ProbingProvider({required this.accepts});

  final bool accepts;
  final probedPasswords = <String>[];

  @override
  bool get requiresCredentials => true;

  @override
  Future<Result<AccountProbe>> probeAccount({
    required String school,
    required String login,
    required String password,
  }) async {
    probedPasswords.add(password);
    return accepts
        ? const Result.success(AccountProbe(schoolName: 'S', students: []))
        : const Result.failure(InvalidCredentials());
  }
}

Future<(ProviderContainer, AccountStorage)> _accountContainer(
  _ProbingProvider provider,
) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final storage = AccountStorage(store: FakeKeyValueStore());
  await storage.saveAccounts([_account]);
  await storage.saveActiveSelection(
    const ActiveSelection(accountId: 'a1', studentId: 6339),
  );
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      accountStorageProvider.overrideWithValue(storage),
      activeDataProviderProvider.overrideWithBuild((ref, _) => provider),
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
      home: ReauthPrompt(child: Scaffold(body: Text('Dashboard'))),
    ),
  );
}

void main() {
  testWidgets('asks for the password when a sync needs it, off Messages', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);

    container.read(reauthRequiredProvider.notifier).value = true;
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
  });

  testWidgets('asks once when the flag was raised before the shell', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(reauthRequiredProvider.notifier).value = true;

    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();
    container.read(reauthRequiredProvider.notifier).value = true;
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('a rejected password keeps the dialog open with an error', (
    tester,
  ) async {
    final provider = _ProbingProvider(accepts: false);
    final (container, storage) = (await tester.runAsync(
      () => _accountContainer(provider),
    ))!;
    container.read(reauthRequiredProvider.notifier).value = true;
    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'wrong');
    await tester.tap(find.text('Log in'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    expect(provider.probedPasswords, ['wrong']);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Invalid credentials'), findsOneWidget);
    final stored = (await tester.runAsync(storage.getAccounts))!;
    expect(stored.single.password, isEmpty);
    expect(container.read(reauthRequiredProvider), isTrue);
  });

  testWidgets('an accepted password is saved and closes the dialog', (
    tester,
  ) async {
    final provider = _ProbingProvider(accepts: true);
    final (container, storage) = (await tester.runAsync(
      () => _accountContainer(provider),
    ))!;
    container.read(reauthRequiredProvider.notifier).value = true;
    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'new');
    await tester.tap(find.text('Log in'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump(const Duration(minutes: 1));

    expect(find.byType(AlertDialog), findsNothing);
    final stored = (await tester.runAsync(storage.getAccounts))!;
    expect(stored.single.password, 'new');
    expect(container.read(reauthRequiredProvider), isFalse);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
}
