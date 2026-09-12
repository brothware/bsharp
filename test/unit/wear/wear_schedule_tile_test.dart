import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/providers/custom_event_providers.dart';
import 'package:bsharp/app/providers/dashboard_providers.dart';
import 'package:bsharp/app/providers/schedule_providers.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/domain/entities/custom_event.dart';
import 'package:bsharp/domain/entities/resolved_event.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:bsharp/wear/screens/wear_schedule_tile.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:bsharp/wear/widgets/wear_scaffold.dart';
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
  bool isSubstitution = false,
  String? roomName,
}) {
  final now = DateTime.now();
  return ResolvedEvent(
    id: id,
    date: DateTime(now.year, now.month, now.day),
    number: number,
    startTime: startTime,
    endTime: endTime,
    subjectId: 10,
    isCancelled: isCancelled,
    isSubstitution: isSubstitution,
    roomName: roomName,
  );
}

Widget _buildTile({
  required SharedPreferences prefs,
  List<ResolvedEvent> resolvedEvents = const [],
  bool highlightFirstAsCurrent = false,
  List<CustomEvent> customEvents = const [],
  List<({int customEventId, DateTime date})> customEventOccurrences = const [],
}) {
  final storage = CredentialStorage(store: FakeKeyValueStore());
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      credentialStorageProvider.overrideWithValue(storage),
      wearScreenShapeProvider.overrideWith((_) => WearScreenShape.rectangular),
      resolvedEventsProvider.overrideWithBuild((ref, _) => resolvedEvents),
      customEventsProvider.overrideWith(() => _FakeCustomEvents(customEvents)),
      customEventOccurrencesProvider.overrideWith(
        () => _FakeCustomEventOccurrences(customEventOccurrences),
      ),
      if (highlightFirstAsCurrent)
        currentLessonProvider.overrideWith((ref) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final entries = ref.watch(scheduleEntriesForDateProvider(today));
          return (current: entries.first, next: null, allEnded: false);
        }),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: WearDisplayScope(
          display: WearDisplay(
            shape: WearScreenShape.rectangular,
            sizeDp: Size(400, 400),
          ),
          child: WearScheduleTile(),
        ),
      ),
    ),
  );
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('WearScheduleTile', () {
    testWidgets('shows empty state when no events', (tester) async {
      await tester.pumpWidget(_buildTile(prefs: prefs));
      await tester.pump();

      expect(find.text('No lessons'), findsOneWidget);
      expect(find.byIcon(Icons.wb_sunny_outlined), findsOneWidget);
    });

    testWidgets('shows lesson items when events exist', (tester) async {
      await tester.pumpWidget(
        _buildTile(
          prefs: prefs,
          resolvedEvents: [
            _resolvedEvent(),
            _resolvedEvent(
              id: 2,
              number: 2,
              startTime: '08:55:00',
              endTime: '09:40:00',
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('08:00'), findsOneWidget);
      expect(find.text('08:55'), findsOneWidget);
    });

    testWidgets('shows strikethrough for cancelled lesson', (tester) async {
      await tester.pumpWidget(
        _buildTile(
          prefs: prefs,
          resolvedEvents: [_resolvedEvent(isCancelled: true)],
        ),
      );
      await tester.pump();

      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      final lessonText = textWidgets.where(
        (t) => t.style?.decoration == TextDecoration.lineThrough,
      );
      expect(lessonText, isNotEmpty);
    });

    testWidgets('shows header with day name and date', (tester) async {
      await tester.pumpWidget(_buildTile(prefs: prefs));
      await tester.pump();

      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('highlights the lesson currentLessonProvider reports', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTile(
          prefs: prefs,
          resolvedEvents: [
            _resolvedEvent(),
            _resolvedEvent(
              id: 2,
              number: 2,
              startTime: '08:55:00',
              endTime: '09:40:00',
            ),
          ],
          highlightFirstAsCurrent: true,
        ),
      );
      await tester.pump();

      final container = tester.widget<Container>(
        find.byKey(const Key('lesson-item')).first,
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.border, isNotNull);
    });

    testWidgets('highlights nothing when currentLessonProvider is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTile(
          prefs: prefs,
          resolvedEvents: [_resolvedEvent()],
        ),
      );
      await tester.pump();

      final container = tester.widget<Container>(
        find.byKey(const Key('lesson-item')).first,
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.border, isNull);
    });

    testWidgets(
      'shows a custom event in time order alongside lessons, marked apart',
      (tester) async {
        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);

        await tester.pumpWidget(
          _buildTile(
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
        expect(find.byIcon(Icons.event), findsOneWidget);

        final eventTop = tester.getTopLeft(find.text('Piano lesson')).dy;
        final lessonTop = tester.getTopLeft(find.text('1')).dy;
        expect(eventTop, lessThan(lessonTop));
      },
    );
  });
}
