import 'package:bsharp/data/services/sync_cache.dart';

class MobiregViewCache {
  MobiregViewCache(this._cache);

  final SyncCache _cache;

  void save(String key, Object data) => _cache.saveView(key, data);

  Object? load(String key) => _cache.loadView(key);
}
