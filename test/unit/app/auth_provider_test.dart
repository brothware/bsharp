import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/router.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';

import '../data/credential_storage_test.dart';

void main() {
  group('AuthNotifier', () {
    late ProviderContainer container;
    late FakeKeyValueStore fakeSecureStorage;
    late CredentialStorage credentialStorage;

    setUp(() {
      fakeSecureStorage = FakeKeyValueStore();
      credentialStorage = CredentialStorage(store: fakeSecureStorage);
    });

    ProviderContainer createContainer() {
      return ProviderContainer(
        overrides: [
          credentialStorageProvider.overrideWithValue(credentialStorage),
        ],
      );
    }

    test('returns unauthenticated when no credentials', () async {
      container = createContainer();

      final state = await container.read(authStateProvider.future);
      expect(state, AuthState.unauthenticated);
    });

    test('returns unauthenticated when credentials but no student', () async {
      await credentialStorage.saveCredentials(
        school: 'sp1',
        login: 'user1',
        passwordHash: 'hash',
      );

      container = createContainer();

      final state = await container.read(authStateProvider.future);
      expect(state, AuthState.unauthenticated);
    });

    test('returns authenticated when credentials and student exist',
        () async {
      await credentialStorage.saveCredentials(
        school: 'sp1',
        login: 'user1',
        passwordHash: 'hash',
      );
      await credentialStorage.saveSelectedStudentId(1);

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
      await credentialStorage.saveCredentials(
        school: 'sp1',
        login: 'user1',
        passwordHash: 'hash',
      );
      await credentialStorage.saveSelectedStudentId(1);

      container = createContainer();
      await container.read(authStateProvider.future);

      await container.read(authStateProvider.notifier).logout();

      final state = await container.read(authStateProvider.future);
      expect(state, AuthState.unauthenticated);

      expect(await credentialStorage.hasCredentials(), isFalse);
      expect(await credentialStorage.hasSelectedStudent(), isFalse);
    });
  });

  group('selectedStudentIdProvider', () {
    test('returns null when no student selected', () async {
      final fakeSecureStorage = FakeKeyValueStore();
      final credentialStorage =
          CredentialStorage(store: fakeSecureStorage);

      final container = ProviderContainer(
        overrides: [
          credentialStorageProvider.overrideWithValue(credentialStorage),
        ],
      );

      final id = await container.read(selectedStudentIdProvider.future);
      expect(id, isNull);
    });

    test('returns student id when set', () async {
      final fakeSecureStorage = FakeKeyValueStore();
      final credentialStorage =
          CredentialStorage(store: fakeSecureStorage);
      await credentialStorage.saveSelectedStudentId(42);

      final container = ProviderContainer(
        overrides: [
          credentialStorageProvider.overrideWithValue(credentialStorage),
        ],
      );

      final id = await container.read(selectedStudentIdProvider.future);
      expect(id, 42);
    });
  });
}
