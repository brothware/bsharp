import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/data/data_sources/local/key_value_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeKeyValueStore fakeStorage;
  late CredentialStorage credentialStorage;

  setUp(() {
    fakeStorage = FakeKeyValueStore();
    credentialStorage = CredentialStorage(store: fakeStorage);
  });

  group('CredentialStorage', () {
    test('child mode pin round-trip', () async {
      expect(await credentialStorage.getChildModePin(), isNull);
      await credentialStorage.saveChildModePin('1234');
      expect(await credentialStorage.getChildModePin(), '1234');
      await credentialStorage.clearChildModePin();
      expect(await credentialStorage.getChildModePin(), isNull);
    });

    test('child mode active round-trip', () async {
      expect(await credentialStorage.isChildModeActive(), isFalse);
      await credentialStorage.saveChildModeActive(active: true);
      expect(await credentialStorage.isChildModeActive(), isTrue);
    });

    test('deepl api key round-trip', () async {
      expect(await credentialStorage.getDeeplApiKey(), isNull);
      await credentialStorage.saveDeeplApiKey('key123');
      expect(await credentialStorage.getDeeplApiKey(), 'key123');
      await credentialStorage.clearDeeplApiKey();
      expect(await credentialStorage.getDeeplApiKey(), isNull);
    });

    test('clearAll removes everything', () async {
      await credentialStorage.saveChildModePin('1234');
      await credentialStorage.saveDeeplApiKey('key');

      await credentialStorage.clearAll();

      expect(await credentialStorage.getChildModePin(), isNull);
      expect(await credentialStorage.getDeeplApiKey(), isNull);
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
