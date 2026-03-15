import 'package:bsharp/data/data_sources/local/key_value_store.dart';
import 'package:bsharp/data/data_sources/local/key_value_store_native.dart'
    if (dart.library.js_interop) 'package:bsharp/data/data_sources/local/key_value_store_web.dart'
    as platform;

class CredentialStorage {
  CredentialStorage({KeyValueStore? store})
    : _store = store ?? platform.createDefaultStore();

  final KeyValueStore _store;

  static const _childModePinKey = 'child_mode_pin';
  static const _childModeActiveKey = 'child_mode_active';
  static const _childModeConfigKey = 'child_mode_config';
  static const _childModeFailedAttemptsKey = 'child_mode_failed_attempts';
  static const _childModeLockedUntilKey = 'child_mode_locked_until';
  static const _deeplApiKeyKey = 'deepl_api_key';

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

  Future<void> clearAll() => _store.deleteAll();
}
