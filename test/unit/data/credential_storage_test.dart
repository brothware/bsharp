import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';

void main() {
  late FakeFlutterSecureStorage fakeStorage;
  late CredentialStorage credentialStorage;

  setUp(() {
    fakeStorage = FakeFlutterSecureStorage();
    credentialStorage = CredentialStorage(storage: fakeStorage);
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
      fakeStorage._data['selected_student_id'] = 'notanumber';
      expect(await credentialStorage.getSelectedStudentId(), isNull);
    });
  });
}

class FakeFlutterSecureStorage implements FlutterSecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _data[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _data[key] = value;
    } else {
      _data.remove(key);
    }
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _data.remove(key);
  }

  @override
  Future<void> deleteAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _data.clear();
  }

  @override
  Future<bool> containsKey({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _data.containsKey(key);
  }

  @override
  Future<Map<String, String>> readAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return Map.from(_data);
  }

  @override
  AndroidOptions get aOptions => AndroidOptions.defaultOptions;

  @override
  IOSOptions get iOptions => IOSOptions.defaultOptions;

  @override
  LinuxOptions get lOptions => LinuxOptions.defaultOptions;

  @override
  MacOsOptions get mOptions => MacOsOptions.defaultOptions;

  @override
  WebOptions get webOptions => WebOptions.defaultOptions;

  @override
  WindowsOptions get wOptions => WindowsOptions.defaultOptions;

  @override
  Future<bool> isCupertinoProtectedDataAvailable() async => true;

  @override
  Stream<bool> get onCupertinoProtectedDataAvailabilityChanged =>
      const Stream.empty();

  @override
  void registerListener({
    required String key,
    required ValueChanged<String?> listener,
  }) {}

  @override
  void unregisterListener({
    required String key,
    required ValueChanged<String?> listener,
  }) {}

  @override
  void unregisterAllListeners() {}

  @override
  void unregisterAllListenersForKey({required String key}) {}
}
