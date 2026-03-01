import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';

import '../../unit/data/credential_storage_test.dart';

CredentialStorage _emptyStorage() =>
    CredentialStorage(storage: FakeFlutterSecureStorage());

void main() {
  group('SyncStatusNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          credentialStorageProvider.overrideWithValue(_emptyStorage()),
        ],
      );
    });

    test('initial state is idle', () {
      expect(container.read(syncStatusProvider), SyncStatus.idle);
    });

    test('sync transitions to syncing then failed without credentials',
        () async {
      final notifier = container.read(syncStatusProvider.notifier);
      final future = notifier.sync();
      expect(container.read(syncStatusProvider), SyncStatus.syncing);
      await future;
      expect(container.read(syncStatusProvider), SyncStatus.failed);
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
      expect(container.read(lastSyncTimeProvider), isNull);
    });

    test('can be updated', () {
      final container = ProviderContainer();
      final now = DateTime.now();
      container.read(lastSyncTimeProvider.notifier).state = now;
      expect(container.read(lastSyncTimeProvider), now);
    });
  });
}
