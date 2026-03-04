import 'package:bsharp/data/data_sources/local/key_value_store.dart';
import 'package:web/web.dart' as web;

KeyValueStore createDefaultStore() => WebKeyValueStore();

class WebKeyValueStore implements KeyValueStore {
  static const _prefix = 'bsharp';

  @override
  Future<String?> read({required String key}) async {
    return web.window.localStorage.getItem('$_prefix.$key');
  }

  @override
  Future<void> write({required String key, required String value}) async {
    web.window.localStorage.setItem('$_prefix.$key', value);
  }

  @override
  Future<void> delete({required String key}) async {
    web.window.localStorage.removeItem('$_prefix.$key');
  }

  @override
  Future<void> deleteAll() async {
    final storage = web.window.localStorage;
    final keysToRemove = <String>[];
    for (var i = 0; i < storage.length; i++) {
      final key = storage.key(i);
      if (key != null && key.startsWith('$_prefix.')) {
        keysToRemove.add(key);
      }
    }
    keysToRemove.forEach(storage.removeItem);
  }
}
