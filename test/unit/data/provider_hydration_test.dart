import 'package:bsharp/app/providers/more_providers.dart';
import 'package:bsharp/app/providers/schedule_providers.dart';
import 'package:bsharp/data/providers/demo/demo_data_provider.dart';
import 'package:bsharp/data/providers/mobireg/mobireg_data_provider.dart';
import 'package:bsharp/data/services/sync_cache.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
  });

  group('MobiregDataProvider.hydrateFromCache', () {
    test('restores schedule and portal state from a populated cache', () {
      final cache = SyncCache(prefs)
        ..saveSyncData({
          'Subjects': [
            {'id': 10, 'name': 'przyroda', 'action': 'I'},
          ],
          'Events': [
            {
              'id': 1,
              'name': '',
              'date': '2026-09-17',
              'number': 1,
              'start_time': '08:00:00',
              'end_time': '08:45:00',
              'event_types_id': 100,
              'status': 0,
              'substitution': 0,
              'type': 1,
              'attr': 0,
              'locked': 0,
            },
          ],
          'EventTypes': [
            {
              'id': 100,
              'subjects_id': 10,
              'teaching_level': 0,
              'substitution': 0,
            },
          ],
        })
        ..savePortalView('tests', [
          {'id': 5, 'subjectName': 'przyroda', 'date': '2026-09-17'},
        ]);

      final restored = MobiregDataProvider().hydrateFromCache(
        container.read(Provider((ref) => ref)),
        cache,
      );

      expect(restored, isTrue);
      expect(container.read(resolvedEventsProvider).single.id, 1);
      expect(container.read(testsProvider).single.subjectName, 'nature');
    });

    test('reports nothing restored when the cache is empty', () {
      final restored = MobiregDataProvider().hydrateFromCache(
        container.read(Provider((ref) => ref)),
        SyncCache(prefs),
      );

      expect(restored, isFalse);
    });
  });

  group('DemoDataProvider.hydrateFromCache', () {
    test('restores nothing because demo regenerates its data', () {
      final restored = DemoDataProvider().hydrateFromCache(
        container.read(Provider((ref) => ref)),
        SyncCache(prefs),
      );

      expect(restored, isFalse);
      expect(container.read(resolvedEventsProvider), isEmpty);
    });
  });

  group('contentLanguage', () {
    test('mobireg writes its free text in Polish', () {
      expect(MobiregDataProvider().contentLanguage, 'pl');
    });

    test('demo writes its free text in English', () {
      expect(DemoDataProvider().contentLanguage, 'en');
    });
  });
}
