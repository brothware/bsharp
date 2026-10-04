import 'package:bsharp/app/child_provider.dart';
import 'package:bsharp/app/providers/attendance_providers.dart';
import 'package:bsharp/app/providers/grades_providers.dart';
import 'package:bsharp/app/providers/more_providers.dart';
import 'package:bsharp/app/providers/schedule_providers.dart';
import 'package:bsharp/data/providers/demo/demo_data_provider.dart';
import 'package:bsharp/data/providers/mobireg/mobireg_data_provider.dart';
import 'package:bsharp/data/providers/mobireg/mobireg_view_cache.dart';
import 'package:bsharp/data/services/sync_cache.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../fixtures/mobireg/fixtures.dart';

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
    MobiregViewCache populatedCache() {
      final views = MobiregViewCache(SyncCache(prefs));
      const fixtures = {
        'users': 'users',
        'terms': 'terms',
        'subjects': 'subjects',
        'marks_4': 'marks_term4',
        'marks_7': 'marks_empty',
        'timetable': 'timetable_events',
        'attendance-stats': 'attendance_stats',
        'tests': 'tests',
        'reprimands': 'reprimands',
        'announcements': 'announcements',
      };
      for (final MapEntry(:key, :value) in fixtures.entries) {
        views.save(key, loadMobiregFixture(value));
      }
      views.save('pupil', 6339);
      return views;
    }

    test('restores every view from a populated cache', () {
      populatedCache();

      final restored = MobiregDataProvider().hydrateFromCache(
        container.read(Provider((ref) => ref)),
        SyncCache(prefs),
        studentId: 6339,
      );

      expect(restored, isTrue);
      expect(container.read(resolvedEventsProvider), isNotEmpty);
      expect(container.read(resolvedGradesProvider), isNotEmpty);
      expect(container.read(attendancesProvider), isNotEmpty);
      expect(container.read(testsProvider), isNotEmpty);
      expect(container.read(studentsProvider).single.id, 6339);
    });

    test('a cache saved for another pupil restores nothing', () {
      populatedCache();

      final restored = MobiregDataProvider().hydrateFromCache(
        container.read(Provider((ref) => ref)),
        SyncCache(prefs),
        studentId: 6541,
      );

      expect(restored, isFalse);
      expect(container.read(resolvedGradesProvider), isEmpty);
      expect(container.read(studentsProvider), isEmpty);
    });

    test('reports nothing restored when the cache is empty', () {
      final restored = MobiregDataProvider().hydrateFromCache(
        container.read(Provider((ref) => ref)),
        SyncCache(prefs),
        studentId: 6339,
      );

      expect(restored, isFalse);
    });

    test('a malformed cached view fails loudly', () {
      populatedCache().save('terms', {'not': 'a list'});

      expect(
        () => MobiregDataProvider().hydrateFromCache(
          container.read(Provider((ref) => ref)),
          SyncCache(prefs),
          studentId: 6339,
        ),
        throwsFormatException,
      );
    });
  });

  group('DemoDataProvider.hydrateFromCache', () {
    test('restores nothing because demo regenerates its data', () {
      final restored = DemoDataProvider().hydrateFromCache(
        container.read(Provider((ref) => ref)),
        SyncCache(prefs),
        studentId: 6339,
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
