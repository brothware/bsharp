import 'package:bsharp/app/data_provider_registry.dart';
import 'package:bsharp/core/platform_capabilities.dart';
import 'package:bsharp/data/data_sources/local/account_storage.dart';
import 'package:bsharp/domain/entities/provider_account.dart';
import 'package:bsharp/domain/school_data_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FcmTokenManager {
  FcmTokenManager({
    required this._accountStorage,
    required this._prefs,
  });

  final AccountStorage _accountStorage;
  final SharedPreferences _prefs;

  static const _lastRegistrationKey = 'fcm_last_registration';

  Future<void> registerTokenForAllAccounts() async {
    if (!isPushSupported) return;
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) {
      debugPrint('FcmTokenManager: no FCM token available');
      return;
    }

    if (token == _prefs.getString(_lastRegistrationKey)) {
      debugPrint('FcmTokenManager: registration unchanged, skipping upload');
      return;
    }

    final accounts = await _accountStorage.getAccounts();
    if (accounts.isEmpty) {
      debugPrint('FcmTokenManager: no accounts to register');
      return;
    }

    var allSucceeded = true;

    for (final account in accounts) {
      final success = await _uploadTokenForAccount(
        account: account,
        token: token,
      );
      if (!success) allSucceeded = false;
    }

    if (allSucceeded) {
      await _prefs.setString(_lastRegistrationKey, token);
      debugPrint(
        'FcmTokenManager: token registered for ${accounts.length} accounts',
      );
    }
  }

  Future<void> registerTokenForAccount(ProviderAccount account) async {
    if (!isPushSupported) return;
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    await _uploadTokenForAccount(account: account, token: token);
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
}
