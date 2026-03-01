import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CredentialStorage {
  CredentialStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

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

  Future<String?> getSchool() => _storage.read(key: _schoolKey);

  Future<String?> getLogin() => _storage.read(key: _loginKey);

  Future<String?> getPasswordHash() => _storage.read(key: _passwordHashKey);

  Future<int?> getSelectedStudentId() async {
    final value = await _storage.read(key: _selectedStudentIdKey);
    return value != null ? int.tryParse(value) : null;
  }

  Future<String?> getMessagesToken() =>
      _storage.read(key: _messagesTokenKey);

  Future<void> saveCredentials({
    required String school,
    required String login,
    required String passwordHash,
  }) async {
    await Future.wait([
      _storage.write(key: _schoolKey, value: school),
      _storage.write(key: _loginKey, value: login),
      _storage.write(key: _passwordHashKey, value: passwordHash),
    ]);
  }

  Future<void> saveSelectedStudentId(int studentId) =>
      _storage.write(
        key: _selectedStudentIdKey,
        value: studentId.toString(),
      );

  Future<void> saveMessagesToken(String token) =>
      _storage.write(key: _messagesTokenKey, value: token);

  Future<String?> getChildModePin() =>
      _storage.read(key: _childModePinKey);

  Future<void> saveChildModePin(String pin) =>
      _storage.write(key: _childModePinKey, value: pin);

  Future<void> clearChildModePin() =>
      _storage.delete(key: _childModePinKey);

  Future<bool> isChildModeActive() async {
    final value = await _storage.read(key: _childModeActiveKey);
    return value == 'true';
  }

  Future<void> saveChildModeActive({required bool active}) =>
      _storage.write(key: _childModeActiveKey, value: active.toString());

  Future<String?> getChildModeConfig() =>
      _storage.read(key: _childModeConfigKey);

  Future<void> saveChildModeConfig(String configJson) =>
      _storage.write(key: _childModeConfigKey, value: configJson);

  Future<int> getChildModeFailedAttempts() async {
    final value = await _storage.read(key: _childModeFailedAttemptsKey);
    return value != null ? (int.tryParse(value) ?? 0) : 0;
  }

  Future<void> saveChildModeFailedAttempts(int attempts) =>
      _storage.write(
        key: _childModeFailedAttemptsKey,
        value: attempts.toString(),
      );

  Future<DateTime?> getChildModeLockedUntil() async {
    final value = await _storage.read(key: _childModeLockedUntilKey);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  Future<void> saveChildModeLockedUntil(DateTime? lockedUntil) async {
    if (lockedUntil == null) {
      await _storage.delete(key: _childModeLockedUntilKey);
    } else {
      await _storage.write(
        key: _childModeLockedUntilKey,
        value: lockedUntil.toIso8601String(),
      );
    }
  }

  Future<void> clearChildModeState() => Future.wait([
        _storage.delete(key: _childModeActiveKey),
        _storage.delete(key: _childModeConfigKey),
        _storage.delete(key: _childModeFailedAttemptsKey),
        _storage.delete(key: _childModeLockedUntilKey),
      ]);

  Future<String?> getDeeplApiKey() =>
      _storage.read(key: _deeplApiKeyKey);

  Future<void> saveDeeplApiKey(String key) =>
      _storage.write(key: _deeplApiKeyKey, value: key);

  Future<void> clearDeeplApiKey() =>
      _storage.delete(key: _deeplApiKeyKey);

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

  Future<void> clearAll() => _storage.deleteAll();
}
