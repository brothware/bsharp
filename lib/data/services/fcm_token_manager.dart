import 'package:bsharp/app/data_provider_registry.dart';
import 'package:bsharp/core/platform_capabilities.dart';
import 'package:bsharp/data/data_sources/local/account_storage.dart';
import 'package:bsharp/domain/entities/provider_account.dart';
import 'package:bsharp/domain/school_data_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class FcmTokenManager {
  FcmTokenManager({
    required AccountStorage accountStorage,
    required SharedPreferences prefs,
  }) : _accountStorage = accountStorage,
       _prefs = prefs;

  final AccountStorage _accountStorage;
  final SharedPreferences _prefs;

  static const _lastTokenKey = 'fcm_last_token';
  static const _deviceIdKey = 'fcm_device_id';

  Future<String> _getDeviceId() async {
    var id = _prefs.getString(_deviceIdKey);
    if (id == null) {
      id = const Uuid().v4();
      await _prefs.setString(_deviceIdKey, id);
    }
    return id;
  }

  Future<void> registerTokenForAllAccounts() async {
    if (!isPushSupported) return;
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) {
      debugPrint('FcmTokenManager: no FCM token available');
      return;
    }

    final lastToken = _prefs.getString(_lastTokenKey);
    if (token == lastToken) {
      debugPrint('FcmTokenManager: token unchanged, skipping upload');
      return;
    }

    final accounts = await _accountStorage.getAccounts();
    if (accounts.isEmpty) {
      debugPrint('FcmTokenManager: no accounts to register');
      return;
    }

    final versionCode = await _getVersionCode();
    final deviceId = await _getDeviceId();
    var allSucceeded = true;

    for (final account in accounts) {
      final success = await _uploadTokenForAccount(
        account: account,
        token: token,
        deviceId: deviceId,
        versionCode: versionCode,
      );
      if (!success) allSucceeded = false;
    }

    if (allSucceeded) {
      await _prefs.setString(_lastTokenKey, token);
      debugPrint(
        'FcmTokenManager: token registered for ${accounts.length} accounts',
      );
    }
  }

  Future<void> registerTokenForAccount(ProviderAccount account) async {
    if (!isPushSupported) return;
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    final deviceId = await _getDeviceId();
    final versionCode = await _getVersionCode();
    await _uploadTokenForAccount(
      account: account,
      token: token,
      deviceId: deviceId,
      versionCode: versionCode,
    );
  }

  void listenForTokenRefresh() {
    if (!isPushSupported) return;
    FirebaseMessaging.instance.onTokenRefresh.listen((_) async {
      await registerTokenForAllAccounts();
    });
  }

  Future<bool> _uploadTokenForAccount({
    required ProviderAccount account,
    required String token,
    required String deviceId,
    required int versionCode,
  }) async {
    final provider = createProviderForType(account.providerType);
    if (!provider.supports(DataProviderCapability.pushNotifications)) {
      return true;
    }

    final passHash = account.password.isNotEmpty
        ? provider.hashPassword(account.password)
        : account.legacyPasswordHash;
    if (passHash == null) {
      debugPrint('FcmTokenManager: no credential for ${account.slug}');
      return false;
    }

    try {
      final ok = await provider.registerPushToken(
        school: account.slug,
        login: account.login,
        passwordHash: passHash,
        token: token,
        deviceId: deviceId,
        appVersionCode: versionCode,
      );
      debugPrint(
        'FcmTokenManager: ${ok ? 'registered' : 'failed'} for ${account.slug}',
      );
      return ok;
    } on Object catch (e) {
      debugPrint('FcmTokenManager: error for ${account.slug}: $e');
      return false;
    }
  }

  Future<int> _getVersionCode() async {
    final info = await PackageInfo.fromPlatform();
    return int.tryParse(info.buildNumber) ?? 1;
  }
}
