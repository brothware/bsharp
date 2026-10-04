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
    Future<String?> Function()? fetchToken,
    SchoolDataProvider Function(String providerType)? providerFor,
  }) : _fetchToken =
           fetchToken ?? (() => FirebaseMessaging.instance.getToken()),
       _providerFor = providerFor ?? createProviderForType;

  final AccountStorage _accountStorage;
  final SharedPreferences _prefs;
  final Future<String?> Function() _fetchToken;
  final SchoolDataProvider Function(String providerType) _providerFor;

  static const _lastRegistrationKey = 'fcm_registration_v2';
  static const _registrationSeparator = '|';

  Future<void> registerTokenForAllAccounts() async {
    if (!isPushSupported) {
      return;
    }
    final token = await _fetchToken();
    if (token == null) {
      debugPrint('FcmTokenManager: no FCM token available');
      return;
    }

    final accounts = await _accountStorage.getAccounts();
    if (accounts.isEmpty) {
      debugPrint('FcmTokenManager: no accounts to register');
      return;
    }

    final registration = _registrationOf(token, accounts);
    if (registration == _prefs.getString(_lastRegistrationKey)) {
      debugPrint('FcmTokenManager: registration unchanged, skipping upload');
      return;
    }

    var allSucceeded = true;

    for (final account in accounts) {
      final success = await _uploadTokenForAccount(
        account: account,
        token: token,
      );
      if (!success) {
        allSucceeded = false;
      }
    }

    if (allSucceeded) {
      await _prefs.setString(_lastRegistrationKey, registration);
      debugPrint(
        'FcmTokenManager: token registered for ${accounts.length} accounts',
      );
    }
  }

  String _registrationOf(String token, List<ProviderAccount> accounts) {
    final registeredIds = [
      for (final account in accounts)
        if (account.password.isNotEmpty) account.id,
    ]..sort();
    return [token, ...registeredIds].join(_registrationSeparator);
  }

  Future<void> registerTokenForAccount(ProviderAccount account) async {
    if (!isPushSupported) return;
    final token = await _fetchToken();
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
    final provider = _providerFor(account.providerType);
    if (!provider.supports(DataProviderCapability.pushNotifications)) {
      return true;
    }

    if (account.password.isEmpty) {
      debugPrint('FcmTokenManager: no password for ${account.slug}, skipping');
      return true;
    }

    try {
      final ok = await provider.registerPushToken(
        school: account.slug,
        login: account.login,
        password: account.password,
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
