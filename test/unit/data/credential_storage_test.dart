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
    test('hasCredentials returns false when empty', () async {
      expect(await credentialStorage.hasCredentials(), isFalse);
    });

    test('saveCredentials and read back', () async {
      await credentialStorage.saveCredentials(
        school: 'sp1',
        login: 'user1',
        passwordHash: 'abc123',
      );

      expect(await credentialStorage.getSchool(), 'sp1');
      expect(await credentialStorage.getLogin(), 'user1');
      expect(await credentialStorage.getPasswordHash(), 'abc123');
    });

    test('hasCredentials returns true after save', () async {
      await credentialStorage.saveCredentials(
        school: 'sp1',
        login: 'user1',
        passwordHash: 'abc123',
      );

      expect(await credentialStorage.hasCredentials(), isTrue);
    });

    test('hasSelectedStudent returns false when not set', () async {
      expect(await credentialStorage.hasSelectedStudent(), isFalse);
    });

    test('saveSelectedStudentId and read back', () async {
      await credentialStorage.saveSelectedStudentId(42);
      expect(await credentialStorage.getSelectedStudentId(), 42);
      expect(await credentialStorage.hasSelectedStudent(), isTrue);
    });

    test('saveMessagesToken and read back', () async {
      await credentialStorage.saveMessagesToken('tok123');
      expect(await credentialStorage.getMessagesToken(), 'tok123');
    });

    test('clearAll removes everything', () async {
      await credentialStorage.saveCredentials(
        school: 'sp1',
        login: 'user1',
        passwordHash: 'abc123',
      );
      await credentialStorage.saveSelectedStudentId(42);
      await credentialStorage.saveMessagesToken('tok');

      await credentialStorage.clearAll();

      expect(await credentialStorage.hasCredentials(), isFalse);
      expect(await credentialStorage.hasSelectedStudent(), isFalse);
      expect(await credentialStorage.getMessagesToken(), isNull);
    });

    test('getSelectedStudentId returns null for invalid value', () async {
      fakeStorage.data['selected_student_id'] = 'notanumber';
      expect(await credentialStorage.getSelectedStudentId(), isNull);
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
