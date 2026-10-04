import 'package:bsharp/app/account_providers.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/data_provider_registry.dart';
import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/data/data_sources/local/account_storage.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/data/providers/demo/demo_data_provider.dart';
import 'package:bsharp/domain/entities/provider_account.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/credential_storage_test.dart';

class _PupilGoneDataProvider extends DemoDataProvider {
  @override
  String get id => 'mobireg';

  @override
  bool get requiresCredentials => true;

  @override
  Future<void> loadSchoolData(
    Ref ref, {
    required int studentId,
    DateTime? now,
  }) async => throw StateError('Pupil $studentId is not on this account');
}

CredentialStorage _emptyStorage() =>
    CredentialStorage(store: FakeKeyValueStore());

void main() {
  group('SyncStatusNotifier', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [
          credentialStorageProvider.overrideWithValue(_emptyStorage()),
          sharedPreferencesProvider.overrideWithValue(prefs),
          accountStorageProvider.overrideWithValue(
            AccountStorage(store: FakeKeyValueStore()),
          ),
        ],
      );
    });

    test('initial state is idle', () {
      expect(container.read(syncStatusProvider), SyncStatus.idle);
    });

    test(
      'sync transitions to syncing then failed without credentials',
      () async {
        final notifier = container.read(syncStatusProvider.notifier);
        final future = notifier.sync();
        expect(container.read(syncStatusProvider), SyncStatus.syncing);
        await future;
        expect(container.read(syncStatusProvider), SyncStatus.failed);
      },
    );

    test('a pupil missing from the account fails the sync', () async {
      final accountStorage = AccountStorage(store: FakeKeyValueStore());
      await accountStorage.saveAccounts([
        const ProviderAccount(
          id: 'a1',
          providerType: 'mobireg',
          slug: 'sp1',
          login: 'p',
          password: 's',
        ),
      ]);
      await accountStorage.saveActiveSelection(
        const ActiveSelection(accountId: 'a1', studentId: 6541),
      );
      final failing = ProviderContainer(
        overrides: [
          credentialStorageProvider.overrideWithValue(_emptyStorage()),
          sharedPreferencesProvider.overrideWithValue(
            container.read(sharedPreferencesProvider),
          ),
          accountStorageProvider.overrideWithValue(accountStorage),
          activeDataProviderProvider.overrideWithBuild(
            (ref, _) => _PupilGoneDataProvider(),
          ),
        ],
      );
      addTearDown(failing.dispose);

      await failing.read(syncStatusProvider.notifier).sync();

      expect(failing.read(syncStatusProvider), SyncStatus.failed);
    });

    test('reset sets state to idle', () async {
      final notifier = container.read(syncStatusProvider.notifier);
      await notifier.sync();
      notifier.reset();
      expect(container.read(syncStatusProvider), SyncStatus.idle);
    });

    test('concurrent sync calls are ignored', () async {
      final notifier = container.read(syncStatusProvider.notifier);
      final future1 = notifier.sync();
      final future2 = notifier.sync();
      await Future.wait([future1, future2]);
      expect(container.read(syncStatusProvider), SyncStatus.failed);
    });
  });

  group('lastSyncTimeProvider', () {
    test('initial value is null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(lastSyncTimeProvider), isNull);
    });

    test('can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final now = DateTime.now();
      container.read(lastSyncTimeProvider.notifier).value = now;
      expect(container.read(lastSyncTimeProvider), now);
    });
  });
}
