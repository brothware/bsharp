import 'package:bsharp/data/data_sources/local/account_storage.dart';
import 'package:bsharp/data/data_sources/local/key_value_store.dart';
import 'package:bsharp/data/services/fcm_token_manager.dart';
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

  test('registerTokenForAllAccounts is a no-op on iOS (no Firebase)', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await expectLater(manager.registerTokenForAllAccounts(), completes);
  });
}
