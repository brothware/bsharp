import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/domain/entities/resolved_event.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:bsharp/presentation/schedule/providers/schedule_providers.dart';
import 'package:bsharp/wear/screens/wear_schedule_tile.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/credential_storage_test.dart';

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
}) {
  final storage = CredentialStorage(store: FakeKeyValueStore());
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      credentialStorageProvider.overrideWithValue(storage),
      wearScreenShapeProvider.overrideWith((_) => WearScreenShape.rectangular),
      resolvedEventsProvider.overrideWithBuild((ref, _) => resolvedEvents),
    ],
    child: const MaterialApp(home: Scaffold(body: WearScheduleTile())),
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
  });
}
