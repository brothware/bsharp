import 'package:bsharp/app/providers/dashboard_providers.dart';
import 'package:bsharp/app/providers/schedule_providers.dart';
import 'package:bsharp/domain/entities/resolved_event.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  ResolvedEvent resolved({
    required DateTime date,
    int id = 1,
    bool isCancelled = false,
  }) {
    return ResolvedEvent(
      id: id,
      date: date,
      number: 1,
      startTime: '08:00:00',
      endTime: '08:45:00',
      isCancelled: isCancelled,
    );
  }

  DateTime dayOffset(int days) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).add(Duration(days: days));
  }

  group('nextSchoolDayProvider', () {
    test('returns tomorrow when it has a non-cancelled lesson', () {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          resolvedEventsProvider.overrideWithBuild(
            (ref, _) => [resolved(date: dayOffset(1))],
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(nextSchoolDayProvider), dayOffset(1));
    });

    test('skips days with only cancelled lessons', () {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          resolvedEventsProvider.overrideWithBuild(
            (ref, _) => [
              resolved(date: dayOffset(1), isCancelled: true),
              resolved(id: 2, date: dayOffset(2)),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(nextSchoolDayProvider), dayOffset(2));
    });

    test('returns null when no future lessons exist', () {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          resolvedEventsProvider.overrideWithBuild((ref, _) => []),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(nextSchoolDayProvider), isNull);
    });
  });
}
