import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/providers/custom_event_providers.dart';
import 'package:bsharp/app/providers/schedule_providers.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/domain/entities/custom_event.dart';
import 'package:bsharp/domain/entities/resolved_event.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:bsharp/wear/screens/wear_schedule_detail_screen.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:bsharp/wear/widgets/wear_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/credential_storage_test.dart';

class _FakeCustomEvents extends CustomEvents {
  _FakeCustomEvents(this._initial);

  final List<CustomEvent> _initial;

  @override
  List<CustomEvent> build() => _initial;
}

class _FakeCustomEventOccurrences extends CustomEventOccurrences {
  _FakeCustomEventOccurrences(this._initial);

  final List<({int customEventId, DateTime date})> _initial;

  @override
  List<({int customEventId, DateTime date})> build() => _initial;
}

ResolvedEvent _resolvedEvent({
  int id = 1,
  int number = 1,
  String startTime = '08:00:00',
  String endTime = '08:45:00',
  bool isCancelled = false,
  DateTime? date,
}) {
  final d = date ?? DateTime.now();
  return ResolvedEvent(
    id: id,
    date: DateTime(d.year, d.month, d.day),
    number: number,
    startTime: startTime,
    endTime: endTime,
    subjectId: 10,
    isCancelled: isCancelled,
  );
}

Widget _buildScreen({
  required SharedPreferences prefs,
  List<ResolvedEvent> resolvedEvents = const [],
  List<CustomEvent> customEvents = const [],
  List<({int customEventId, DateTime date})> customEventOccurrences = const [],
  WearScreenShape shape = WearScreenShape.rectangular,
}) {
  final storage = CredentialStorage(store: FakeKeyValueStore());
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      credentialStorageProvider.overrideWithValue(storage),
      wearScreenShapeProvider.overrideWith((_) => shape),
      resolvedEventsProvider.overrideWithBuild((ref, _) => resolvedEvents),
      customEventsProvider.overrideWith(() => _FakeCustomEvents(customEvents)),
      customEventOccurrencesProvider.overrideWith(
        () => _FakeCustomEventOccurrences(customEventOccurrences),
      ),
    ],
    child: const MaterialApp(home: WearScheduleDetailScreen()),
  );
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('WearScheduleDetailScreen', () {
    testWidgets('shows day label with date', (tester) async {
      await tester.pumpWidget(_buildScreen(prefs: prefs));
      await tester.pump();

      final now = DateTime.now();
      final formatted =
          '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}';
      expect(find.text(formatted), findsOneWidget);
    });

    testWidgets('shows no lessons text when empty', (tester) async {
      await tester.pumpWidget(_buildScreen(prefs: prefs));
      await tester.pump();

      expect(find.text('No lessons'), findsOneWidget);
    });

    testWidgets('shows lesson entries for today', (tester) async {
      await tester.pumpWidget(
        _buildScreen(
          prefs: prefs,
          resolvedEvents: [
            _resolvedEvent(),
            _resolvedEvent(
              id: 2,
              number: 2,
              startTime: '09:00:00',
              endTime: '09:45:00',
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.text('08:00 - 08:45'), findsOneWidget);
      expect(find.text('09:00 - 09:45'), findsOneWidget);
    });

    testWidgets('shows period selector chevrons', (tester) async {
      await tester.pumpWidget(_buildScreen(prefs: prefs));
      await tester.pump();

      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('a day with lessons still draws them after an empty day', (
      tester,
    ) async {
      final today = DateTime.now();
      final tomorrow = today.add(const Duration(days: 1));

      await tester.pumpWidget(
        _buildScreen(
          prefs: prefs,
          shape: WearScreenShape.round,
          resolvedEvents: [_resolvedEvent(date: today)],
        ),
      );
      await tester.pump();

      expect(find.byType(ListView), findsOneWidget);
      final withLessons = tester.getSize(find.byType(ListView));

      // Forward to a day with nothing on it, then straight back.
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      expect(find.text('No lessons'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      expect(
        find.text('No lessons'),
        findsNothing,
        reason: 'the day has a lesson on it, ${tomorrow.day} did not',
      );
      expect(
        tester.getSize(find.byType(ListView)),
        withLessons,
        reason: 'the list is back but it is drawing nothing',
      );
      expect(find.byType(WearListItem), findsWidgets);
    });

    testWidgets('tapping forward shows next day items, back returns', (
      tester,
    ) async {
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final tomorrowDate = todayDate.add(const Duration(days: 1));

      await tester.pumpWidget(
        _buildScreen(
          prefs: prefs,
          resolvedEvents: [
            _resolvedEvent(),
            _resolvedEvent(
              id: 2,
              startTime: '09:00:00',
              endTime: '09:45:00',
              date: tomorrowDate,
            ),
          ],
        ),
      );
      await tester.pump();

      final element = tester.element(find.byType(WearScheduleDetailScreen));
      final container = ProviderScope.containerOf(element);
      expect(
        container.read(timelineItemsForDateProvider(tomorrowDate)),
        isNotEmpty,
      );

      expect(find.text('08:00 - 08:45'), findsOneWidget);
      expect(find.text('09:00 - 09:45'), findsNothing);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pump();

      expect(find.text('09:00 - 09:45'), findsOneWidget);
      expect(find.text('08:00 - 08:45'), findsNothing);

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pump();

      expect(find.text('08:00 - 08:45'), findsOneWidget);
      expect(find.text('09:00 - 09:45'), findsNothing);
    });

    testWidgets(
      'shows a custom event in time order with the lessons, marked apart',
      (tester) async {
        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);

        await tester.pumpWidget(
          _buildScreen(
            prefs: prefs,
            resolvedEvents: [
              _resolvedEvent(startTime: '09:00:00', endTime: '09:45:00'),
            ],
            customEvents: [
              const CustomEvent(
                id: 1,
                accountId: 1,
                title: 'Piano lesson',
                startTime: '08:00:00',
                endTime: '08:30:00',
              ),
            ],
            customEventOccurrences: [
              (customEventId: 1, date: todayDate),
            ],
          ),
        );
        await tester.pump();

        expect(find.text('Piano lesson'), findsOneWidget);
        expect(find.text('08:00 - 08:30'), findsOneWidget);
        expect(find.byIcon(Icons.event), findsOneWidget);

        final eventTop = tester.getTopLeft(find.text('Piano lesson')).dy;
        final lessonTop = tester.getTopLeft(find.text('09:00 - 09:45')).dy;
        expect(eventTop, lessThan(lessonTop));
      },
    );
  });
}
