import 'package:bsharp/app/account_providers.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/router.dart';
import 'package:bsharp/data/data_sources/local/account_storage.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/data/data_sources/local/key_value_store.dart';
import 'package:bsharp/domain/entities/provider_account.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AuthNotifier', () {
    late ProviderContainer container;
    late FakeKeyValueStore fakeAccountStore;
    late AccountStorage accountStorage;
    late FakeKeyValueStore fakeCredStore;
    late CredentialStorage credentialStorage;

    setUp(() {
      fakeAccountStore = FakeKeyValueStore();
      accountStorage = AccountStorage(store: fakeAccountStore);
      fakeCredStore = FakeKeyValueStore();
      credentialStorage = CredentialStorage(store: fakeCredStore);
    });

    ProviderContainer createContainer({SharedPreferences? prefs}) {
      return ProviderContainer(
        overrides: [
          accountStorageProvider.overrideWithValue(accountStorage),
          credentialStorageProvider.overrideWithValue(credentialStorage),
          if (prefs != null) sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
    }

    test('returns unauthenticated when no active selection', () async {
      container = createContainer();

      final state = await container.read(authStateProvider.future);
      expect(state, AuthState.unauthenticated);
    });

    test('returns authenticated when active selection exists', () async {
      await accountStorage.addAccount(
        const ProviderAccount(
          id: 'acc1',
          providerType: 'mobireg',
          slug: 'sp1',
          login: 'user1',
          password: 'secret',
          students: [AccountStudent(id: 1, name: 'Jan', surname: 'K')],
        ),
      );
      await accountStorage.saveActiveSelection(
        const ActiveSelection(accountId: 'acc1', studentId: 1),
      );

      container = createContainer();

      final state = await container.read(authStateProvider.future);
      expect(state, AuthState.authenticated);
    });

    test('completeSetup sets state to authenticated', () async {
      container = createContainer();
      await container.read(authStateProvider.future);

      await container.read(authStateProvider.notifier).completeSetup();
      final state = await container.read(authStateProvider.future);
      expect(state, AuthState.authenticated);
    });

    test('logout clears storage and sets unauthenticated', () async {
      await accountStorage.addAccount(
        const ProviderAccount(
          id: 'acc1',
          providerType: 'mobireg',
          slug: 'sp1',
          login: 'user1',
          password: 'secret',
          students: [AccountStudent(id: 1, name: 'Jan', surname: 'K')],
        ),
      );
      await accountStorage.saveActiveSelection(
        const ActiveSelection(accountId: 'acc1', studentId: 1),
      );

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      container = createContainer(prefs: prefs);
      await container.read(authStateProvider.future);

      await container.read(authStateProvider.notifier).logout();

      final state = await container.read(authStateProvider.future);
      expect(state, AuthState.unauthenticated);

      expect(await accountStorage.hasActiveSelection(), isFalse);
    });
  });

  group('selectedStudentIdProvider', () {
    test('returns null when no active selection', () async {
      final fakeStore = FakeKeyValueStore();
      final accountStore = AccountStorage(store: fakeStore);

      final container = ProviderContainer(
        overrides: [
          accountStorageProvider.overrideWithValue(accountStore),
        ],
      );

      final id = await container.read(selectedStudentIdProvider.future);
      expect(id, isNull);
    });

    test('returns student id when selection set', () async {
      final fakeStore = FakeKeyValueStore();
      final accountStore = AccountStorage(store: fakeStore);
      await accountStore.saveActiveSelection(
        const ActiveSelection(accountId: 'acc1', studentId: 42),
      );

      final container = ProviderContainer(
        overrides: [
          accountStorageProvider.overrideWithValue(accountStore),
        ],
      );

      final id = await container.read(selectedStudentIdProvider.future);
      expect(id, 42);
    });
  });
}

class FakeKeyValueStore implements KeyValueStore {
  final Map<String, String> data = {};

  @override
  Future<String?> read({required String key}) async => data[key];

  @override
  Future<void> write({required String key, required String value}) async {
    data[key] = value;
  }

  @override
  Future<void> delete({required String key}) async {
    data.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    data.clear();
  }
}
