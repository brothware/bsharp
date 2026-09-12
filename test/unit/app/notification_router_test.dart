import 'dart:async';

import 'package:bsharp/app/account_providers.dart';
import 'package:bsharp/app/app.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/notification_router.dart';
import 'package:bsharp/app/router.dart';
import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/data/data_sources/local/account_storage.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/data/services/notification_service.dart';
import 'package:bsharp/domain/entities/provider_account.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/credential_storage_test.dart';

Future<AccountStorage> _accountStorageWithTwoStudents() async {
  final storage = AccountStorage(store: FakeKeyValueStore());
  await storage.saveAccounts([
    const ProviderAccount(
      id: 'a1',
      providerType: 'mobireg',
      slug: 'osm-wroclaw',
      login: 'login1',
      students: [AccountStudent(id: 1, name: 'Jan', surname: 'Kowalski')],
    ),
    const ProviderAccount(
      id: 'a2',
      providerType: 'mobireg',
      slug: 'osm-wroclaw',
      login: 'login2',
      students: [AccountStudent(id: 2, name: 'Ola', surname: 'Nowak')],
    ),
  ]);
  return storage;
}

class _RecordingActiveSelectionNotifier extends ActiveSelectionNotifier {
  int selectCalls = 0;

  @override
  Future<void> select(ActiveSelection selection) async {
    selectCalls++;
    await super.select(selection);
  }
}

Future<WidgetRef> _captureRef(
  WidgetTester tester,
  Widget Function(Widget child) wrapWithProviderScope,
) async {
  late WidgetRef capturedRef;
  await tester.pumpWidget(
    wrapWithProviderScope(
      Consumer(
        builder: (context, ref, _) {
          capturedRef = ref;
          return const SizedBox();
        },
      ),
    ),
  );
  return capturedRef;
}

void main() {
  group('NotificationRouter', () {
    testWidgets('a null router does not throw and does nothing', (
      tester,
    ) async {
      final accountStorage = await _accountStorageWithTwoStudents();
      final ref = await _captureRef(
        tester,
        (child) => ProviderScope(
          overrides: [
            accountStorageProvider.overrideWithValue(accountStorage),
          ],
          child: child,
        ),
      );
      await ref.read(activeSelectionProvider.future);

      expect(
        () =>
            NotificationRouter(
              ref: ref,
              routerProvider: () => null,
            ).handleNotificationTap(
              const NotificationPayload(route: AppRoutes.grades),
            ),
        returnsNormally,
      );
    });

    testWidgets('a payload with a route navigates to it', (tester) async {
      final accountStorage = await _accountStorageWithTwoStudents();
      final ref = await _captureRef(
        tester,
        (child) => ProviderScope(
          overrides: [
            accountStorageProvider.overrideWithValue(accountStorage),
          ],
          child: child,
        ),
      );
      await ref.read(activeSelectionProvider.future);

      final router = createRouter(authState: AuthState.authenticated);

      NotificationRouter(
        ref: ref,
        routerProvider: () => router,
      ).handleNotificationTap(
        const NotificationPayload(route: AppRoutes.grades),
      );
      await tester.pump();

      expect(router.routeInformationProvider.value.uri.path, '/grades');
    });

    testWidgets('a payload with no route does nothing', (tester) async {
      final accountStorage = await _accountStorageWithTwoStudents();
      final ref = await _captureRef(
        tester,
        (child) => ProviderScope(
          overrides: [
            accountStorageProvider.overrideWithValue(accountStorage),
          ],
          child: child,
        ),
      );
      await ref.read(activeSelectionProvider.future);

      final router = createRouter(authState: AuthState.authenticated);
      final notificationRouter = NotificationRouter(
        ref: ref,
        routerProvider: () => router,
      );
      final locationBefore = router.routeInformationProvider.value.uri.path;

      notificationRouter.handleNotificationTap(
        const NotificationPayload(accountId: 'a2', studentId: 2),
      );
      await tester.pump();

      expect(
        router.routeInformationProvider.value.uri.path,
        locationBefore,
      );
      expect(await ref.read(activeSelectionProvider.future), isNull);
    });

    testWidgets(
      'a payload naming another student switches selection before navigating',
      (tester) async {
        final accountStorage = await _accountStorageWithTwoStudents();
        await accountStorage.saveActiveSelection(
          const ActiveSelection(accountId: 'a1', studentId: 1),
        );
        final ref = await _captureRef(
          tester,
          (child) => ProviderScope(
            overrides: [
              accountStorageProvider.overrideWithValue(accountStorage),
            ],
            child: child,
          ),
        );
        await ref.read(activeSelectionProvider.future);

        final router = createRouter(authState: AuthState.authenticated);

        NotificationRouter(
          ref: ref,
          routerProvider: () => router,
        ).handleNotificationTap(
          const NotificationPayload(
            accountId: 'a2',
            studentId: 2,
            route: AppRoutes.grades,
          ),
        );
        await tester.pump();

        final selection = await ref.read(activeSelectionProvider.future);
        expect(selection?.accountId, 'a2');
        expect(selection?.studentId, 2);
        expect(router.routeInformationProvider.value.uri.path, '/grades');
      },
    );

    testWidgets(
      'a payload for the already-selected student does not re-select',
      (tester) async {
        final accountStorage = await _accountStorageWithTwoStudents();
        await accountStorage.saveActiveSelection(
          const ActiveSelection(accountId: 'a1', studentId: 1),
        );
        late _RecordingActiveSelectionNotifier recordingNotifier;
        final ref = await _captureRef(
          tester,
          (child) => ProviderScope(
            overrides: [
              accountStorageProvider.overrideWithValue(accountStorage),
              activeSelectionProvider.overrideWith(
                () => recordingNotifier = _RecordingActiveSelectionNotifier(),
              ),
            ],
            child: child,
          ),
        );
        await ref.read(activeSelectionProvider.future);

        final router = createRouter(authState: AuthState.authenticated);

        NotificationRouter(
          ref: ref,
          routerProvider: () => router,
        ).handleNotificationTap(
          const NotificationPayload(
            accountId: 'a1',
            studentId: 1,
            route: AppRoutes.grades,
          ),
        );
        await tester.pump();

        expect(recordingNotifier.selectCalls, 0);
        expect(router.routeInformationProvider.value.uri.path, '/grades');
      },
    );
  });

  group('BSharpApp router caching', () {
    testWidgets(
      'the same GoRouter instance survives rebuilds while authState '
      'is unchanged',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              notificationServiceProvider.overrideWithValue(
                _NoopNotificationService(),
              ),
              credentialStorageProvider.overrideWithValue(
                CredentialStorage(store: FakeKeyValueStore()),
              ),
              accountStorageProvider.overrideWithValue(
                AccountStorage(store: FakeKeyValueStore()),
              ),
            ],
            child: TranslationProvider(child: const BSharpApp()),
          ),
        );
        await tester.pump();
        await tester.pump();

        final routerBefore = tester
            .widget<MaterialApp>(find.byType(MaterialApp))
            .routerConfig;
        expect(routerBefore, isNotNull);

        final container = ProviderScope.containerOf(
          tester.element(find.byType(BSharpApp)),
        );
        await container.read(themeModeProvider.notifier).toggle();
        await tester.pump();
        await tester.pump();

        final routerAfter = tester
            .widget<MaterialApp>(find.byType(MaterialApp))
            .routerConfig;
        expect(identical(routerBefore, routerAfter), isTrue);
      },
    );

    testWidgets(
      'a cold-start payload arriving before the router exists is not '
      'lost, and navigates once the router is built',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final authNotifier = _DelayedAuthNotifier();
        final service = _LaunchPayloadNotificationService()
          ..launchPayload = const NotificationPayload(route: AppRoutes.grades);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              notificationServiceProvider.overrideWithValue(service),
              credentialStorageProvider.overrideWithValue(
                CredentialStorage(store: FakeKeyValueStore()),
              ),
              accountStorageProvider.overrideWithValue(
                AccountStorage(store: FakeKeyValueStore()),
              ),
              authStateProvider.overrideWith(() => authNotifier),
            ],
            child: TranslationProvider(child: const BSharpApp()),
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(
          () => tester.widget<MaterialApp>(find.byType(MaterialApp)),
          returnsNormally,
          reason: 'the cold-start payload must not crash while auth loads',
        );
        expect(
          tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig,
          isNull,
        );

        authNotifier.completer.complete(AuthState.authenticated);
        await tester.pump();
        await tester.pump();
        await tester.pump();

        final router =
            tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig!
                as GoRouter;
        expect(router.routeInformationProvider.value.uri.path, '/grades');
      },
    );
  });
}

class _NoopNotificationService extends NotificationService {
  @override
  Future<void> initialize({void Function(NotificationPayload)? onTap}) async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<NotificationPayload?> getLaunchPayload() async => null;
}

class _LaunchPayloadNotificationService extends NotificationService {
  NotificationPayload? launchPayload;

  @override
  Future<void> initialize({void Function(NotificationPayload)? onTap}) async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<NotificationPayload?> getLaunchPayload() async => launchPayload;
}

class _DelayedAuthNotifier extends AsyncNotifier<AuthState>
    implements AuthNotifier {
  final completer = Completer<AuthState>();

  @override
  Future<AuthState> build() => completer.future;

  @override
  Future<void> completeSetup() async {}

  @override
  Future<void> logout() async {}
}
