import 'dart:async';

import 'package:bsharp/app/account_providers.dart';
import 'package:bsharp/app/data_provider_registry.dart';
import 'package:bsharp/app/reauth_provider.dart';
import 'package:bsharp/app/saved_passwords_provider.dart';
import 'package:bsharp/app/watch_link_provider.dart';
import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/data/data_sources/local/account_storage.dart';
import 'package:bsharp/data/providers/demo/demo_data_provider.dart';
import 'package:bsharp/domain/entities/account_handoff.dart';
import 'package:bsharp/domain/entities/provider_account.dart';
import 'package:bsharp/domain/entities/saved_login.dart';
import 'package:bsharp/domain/saved_passwords.dart';
import 'package:bsharp/domain/school_data_provider.dart';
import 'package:bsharp/domain/watch_link.dart';
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

class _SavedPasswords implements SavedPasswords {
  _SavedPasswords(this.pickResult);

  final SavedLoginPick pickResult;

  @override
  Future<void> offerToSave(SavedLogin login) async {}

  @override
  Future<SavedLoginPick> pick() async => pickResult;
}

class _PhoneLink implements WatchLink {
  final accounts = StreamController<AccountHandoff>.broadcast();

  @override
  Future<bool> hasConnectedCounterpart() async => true;

  @override
  Future<void> sendAccount(AccountHandoff account) async {}

  @override
  Stream<AccountHandoff> get receivedAccounts => accounts.stream;
}

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
  }) async {
    probedPasswords.add(password);
    return accepts
        ? const Result.success(AccountProbe(schoolName: 'S', students: []))
        : const Result.failure(InvalidCredentials());
  }

  final probedPasswords = <String>[];
}

Future<(ProviderContainer, AccountStorage)> _container(
  _ProbingProvider provider, {
  SavedPasswords? savedPasswords,
  WatchLink? watchLink,
}) async {
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
      savedPasswordsProvider.overrideWithValue(
        savedPasswords ?? _SavedPasswords(const NoSavedLogin()),
      ),
      watchLinkProvider.overrideWithValue(watchLink ?? _PhoneLink()),
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
  await tester.tap(find.text('Type it on the watch'));
  await tester.pumpAndSettle();
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

  testWidgets('a swipe closes the sign-in-again screen', (tester) async {
    final (container, _) = (await tester.runAsync(
      () => _container(_ProbingProvider(accepts: true)),
    ))!;
    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();
    container.read(reauthRequiredProvider.notifier).value = true;
    await tester.pumpAndSettle();

    await tester.dragFrom(const Offset(5, 200), const Offset(300, 0));
    await tester.pumpAndSettle();

    expect(find.text('Sign in again'), findsNothing);
    expect(find.text('Home'), findsOneWidget);
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

  group('signing in again without typing', () {
    Future<_ProbingProvider> openPrompt(
      WidgetTester tester, {
      SavedPasswords? savedPasswords,
      WatchLink? watchLink,
    }) async {
      final provider = _ProbingProvider(accepts: true);
      final (container, _) = (await tester.runAsync(
        () => _container(
          provider,
          savedPasswords: savedPasswords,
          watchLink: watchLink,
        ),
      ))!;
      await tester.pumpWidget(_app(container));
      await tester.pumpAndSettle();
      container.read(reauthRequiredProvider.notifier).value = true;
      await tester.pumpAndSettle();
      return provider;
    }

    Future<void> settle(WidgetTester tester) async {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }

    testWidgets('the prompt asks for no typing up front', (tester) async {
      await openPrompt(tester);

      expect(find.text('Use phone'), findsOneWidget);
      expect(find.text('Saved password'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Type it on the watch'), findsOneWidget);
    });

    testWidgets('a saved password for this account signs in again', (
      tester,
    ) async {
      final provider = await openPrompt(
        tester,
        savedPasswords: _SavedPasswords(
          const SavedLoginPicked(
            SavedLogin(school: 'sp1', login: 'p', password: 'saved'),
          ),
        ),
      );

      await tester.tap(find.text('Saved password'));
      await settle(tester);

      expect(provider.probedPasswords, ['saved']);
      expect(find.text('Sign in again'), findsNothing);
    }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

    testWidgets('a saved password for another account is refused', (
      tester,
    ) async {
      final provider = await openPrompt(
        tester,
        savedPasswords: _SavedPasswords(
          const SavedLoginPicked(
            SavedLogin(school: 'sp2', login: 'p', password: 'saved'),
          ),
        ),
      );

      await tester.tap(find.text('Saved password'));
      await settle(tester);

      expect(provider.probedPasswords, isEmpty);
      expect(find.text('That is a different account'), findsOneWidget);
    });

    testWidgets('the phone can send this account again', (tester) async {
      final link = _PhoneLink();
      addTearDown(link.accounts.close);
      final provider = await openPrompt(tester, watchLink: link);

      await tester.tap(find.text('Use phone'));
      await settle(tester);
      link.accounts.add(
        const AccountHandoff(
          providerType: 'mobireg',
          school: 'sp1',
          login: 'p',
          password: 'from phone',
        ),
      );
      await settle(tester);

      expect(provider.probedPasswords, ['from phone']);
      expect(find.text('Sign in again'), findsNothing);
    }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
  });
}
