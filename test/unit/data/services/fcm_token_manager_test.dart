import 'package:bsharp/data/data_sources/local/account_storage.dart';
import 'package:bsharp/data/data_sources/local/key_value_store.dart';
import 'package:bsharp/data/providers/demo/demo_data_provider.dart';
import 'package:bsharp/data/services/fcm_token_manager.dart';
import 'package:bsharp/domain/entities/provider_account.dart';
import 'package:bsharp/domain/school_data_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _InMemoryStore implements KeyValueStore {
  final _map = <String, String>{};
  @override
  Future<String?> read({required String key}) async => _map[key];
  @override
  Future<void> write({required String key, required String value}) async =>
      _map[key] = value;
  @override
  Future<void> delete({required String key}) async => _map.remove(key);
  @override
  Future<void> deleteAll() async => _map.clear();
}

class _PushProvider extends DemoDataProvider {
  final registeredLogins = <String>[];

  @override
  Set<DataProviderCapability> get capabilities => {
    DataProviderCapability.pushNotifications,
  };

  @override
  Future<bool> registerPushToken({
    required String school,
    required String login,
    required String password,
    required String token,
  }) async {
    registeredLogins.add(login);
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FcmTokenManager manager;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    manager = FcmTokenManager(
      accountStorage: AccountStorage(store: _InMemoryStore()),
      prefs: prefs,
    );
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('a password-less account is skipped, not a failed upload', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = AccountStorage(store: _InMemoryStore());
    await storage.saveAccounts(const [
      ProviderAccount(
        id: 'old',
        providerType: 'mobireg',
        slug: 'sp1',
        login: 'legacy',
      ),
      ProviderAccount(
        id: 'new',
        providerType: 'mobireg',
        slug: 'sp1',
        login: 'current',
        password: 's',
      ),
    ]);
    final provider = _PushProvider();

    await FcmTokenManager(
      accountStorage: storage,
      prefs: prefs,
      fetchToken: () async => 'fcm-123',
      providerFor: (_) => provider,
    ).registerTokenForAllAccounts();

    expect(provider.registeredLogins, ['current']);
    expect(prefs.getString('fcm_last_registration'), 'fcm-123');
  });

  test('registerTokenForAllAccounts is a no-op on iOS (no Firebase)', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await expectLater(manager.registerTokenForAllAccounts(), completes);
  });
}
