import 'package:bsharp/data/data_sources/local/key_value_store.dart';
import 'package:bsharp/data/data_sources/local/key_value_store_native.dart'
    if (dart.library.js_interop) 'package:bsharp/data/data_sources/local/key_value_store_web.dart'
    as platform;

class CredentialStorage {
  CredentialStorage({KeyValueStore? store})
    : _store = store ?? platform.createDefaultStore();

  final KeyValueStore _store;

  static const _schoolKey = 'school';
  static const _loginKey = 'login';
  static const _passwordHashKey = 'password_hash';
  static const _selectedStudentIdKey = 'selected_student_id';
  static const _messagesTokenKey = 'messages_token';
  static const _childModePinKey = 'child_mode_pin';
  static const _childModeActiveKey = 'child_mode_active';
  static const _childModeConfigKey = 'child_mode_config';
  static const _childModeFailedAttemptsKey = 'child_mode_failed_attempts';
  static const _childModeLockedUntilKey = 'child_mode_locked_until';
  static const _deeplApiKeyKey = 'deepl_api_key';

  Future<String?> getSchool() => _store.read(key: _schoolKey);

  Future<String?> getLogin() => _store.read(key: _loginKey);

  Future<String?> getPasswordHash() => _store.read(key: _passwordHashKey);

  Future<int?> getSelectedStudentId() async {
    final value = await _store.read(key: _selectedStudentIdKey);
    return value != null ? int.tryParse(value) : null;
  }

  Future<String?> getMessagesToken() => _store.read(key: _messagesTokenKey);

  Future<void> saveCredentials({
    required String school,
    required String login,
    required String passwordHash,
  }) async {
    await Future.wait([
      _store.write(key: _schoolKey, value: school),
      _store.write(key: _loginKey, value: login),
      _store.write(key: _passwordHashKey, value: passwordHash),
    ]);
  }

  Future<void> saveSelectedStudentId(int studentId) =>
      _store.write(key: _selectedStudentIdKey, value: studentId.toString());

  Future<void> saveMessagesToken(String token) =>
      _store.write(key: _messagesTokenKey, value: token);

  Future<String?> getChildModePin() => _store.read(key: _childModePinKey);

  Future<void> saveChildModePin(String pin) =>
      _store.write(key: _childModePinKey, value: pin);

  Future<void> clearChildModePin() => _store.delete(key: _childModePinKey);

  Future<bool> isChildModeActive() async {
    final value = await _store.read(key: _childModeActiveKey);
    return value == 'true';
  }

  Future<void> saveChildModeActive({required bool active}) =>
      _store.write(key: _childModeActiveKey, value: active.toString());

  Future<String?> getChildModeConfig() => _store.read(key: _childModeConfigKey);

  Future<void> saveChildModeConfig(String configJson) =>
      _store.write(key: _childModeConfigKey, value: configJson);

  Future<int> getChildModeFailedAttempts() async {
    final value = await _store.read(key: _childModeFailedAttemptsKey);
    return value != null ? (int.tryParse(value) ?? 0) : 0;
  }

  Future<void> saveChildModeFailedAttempts(int attempts) => _store.write(
    key: _childModeFailedAttemptsKey,
    value: attempts.toString(),
  );

  Future<DateTime?> getChildModeLockedUntil() async {
    final value = await _store.read(key: _childModeLockedUntilKey);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  Future<void> saveChildModeLockedUntil(DateTime? lockedUntil) async {
    if (lockedUntil == null) {
      await _store.delete(key: _childModeLockedUntilKey);
    } else {
      await _store.write(
        key: _childModeLockedUntilKey,
        value: lockedUntil.toIso8601String(),
      );
    }
  }

  Future<void> clearChildModeState() => Future.wait([
    _store.delete(key: _childModeActiveKey),
    _store.delete(key: _childModeConfigKey),
    _store.delete(key: _childModeFailedAttemptsKey),
    _store.delete(key: _childModeLockedUntilKey),
  ]);

  Future<String?> getDeeplApiKey() => _store.read(key: _deeplApiKeyKey);

  Future<void> saveDeeplApiKey(String key) =>
      _store.write(key: _deeplApiKeyKey, value: key);

  Future<void> clearDeeplApiKey() => _store.delete(key: _deeplApiKeyKey);

  Future<bool> hasCredentials() async {
    final results = await Future.wait([
      getSchool(),
      getLogin(),
      getPasswordHash(),
    ]);
    return results.every((v) => v != null);
  }

  Future<bool> hasSelectedStudent() async {
    final id = await getSelectedStudentId();
    return id != null;
  }

  Future<void> clearAll() => _store.deleteAll();
}
