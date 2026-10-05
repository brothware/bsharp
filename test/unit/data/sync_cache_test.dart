import 'package:bsharp/data/services/sync_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SyncCache', () {
    test('construction removes the payloads of the legacy transport', () async {
      SharedPreferences.setMockInitialValues({
        'cache_sync_data': '{}',
        'cache_portal_marks': '[]',
        'cache_portal_users': '[]',
        'cache_messages_inbox': '[]',
        'mobireg_view_timetable': '[]',
        'unrelated': 'kept',
      });
      final prefs = await SharedPreferences.getInstance();

      SyncCache(prefs);

      expect(prefs.containsKey('cache_sync_data'), isFalse);
      expect(prefs.containsKey('cache_portal_marks'), isFalse);
      expect(prefs.containsKey('cache_portal_users'), isFalse);
      expect(prefs.containsKey('cache_messages_inbox'), isTrue);
      expect(prefs.containsKey('mobireg_view_timetable'), isTrue);
      expect(prefs.getString('unrelated'), 'kept');
    });

    test('an area sync time round-trips per scope', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final cache = SyncCache(prefs);
      final at = DateTime(2026, 10, 5, 8, 15);

      cache.saveAreaSyncedAt('a1_1', 'messages', at);

      expect(cache.loadAreaSyncedAt('a1_1', 'messages'), at);
      expect(cache.loadAreaSyncedAt('a1_2', 'messages'), isNull);
      expect(cache.loadAreaSyncedAt('a1_1', 'grades'), isNull);
    });

    test('clear removes area sync times', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final cache = SyncCache(prefs)
        ..saveAreaSyncedAt('a1_1', 'messages', DateTime(2026))
        ..clear();

      expect(cache.loadAreaSyncedAt('a1_1', 'messages'), isNull);
    });
  });
}
