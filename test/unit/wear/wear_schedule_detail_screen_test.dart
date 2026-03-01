import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/domain/entities/event.dart';
import 'package:bsharp/presentation/schedule/providers/schedule_providers.dart';
import 'package:bsharp/wear/screens/wear_schedule_detail_screen.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';

import '../data/credential_storage_test.dart';

Event _event({
  int id = 1,
  int number = 1,
  String startTime = '08:00:00',
  String endTime = '08:45:00',
  int status = 1,
  DateTime? date,
}) {
  final d = date ?? DateTime.now();
  return Event(
    id: id,
    date: DateTime(d.year, d.month, d.day),
    number: number,
    startTime: startTime,
    endTime: endTime,
    eventTypesId: 10,
    status: status,
    substitution: 0,
    type: 0,
    attr: 0,
    locked: 0,
  );
}

Widget _buildScreen({List<Event> events = const []}) {
  final storage = CredentialStorage(storage: FakeFlutterSecureStorage());
  return ProviderScope(
    overrides: [
      credentialStorageProvider.overrideWithValue(storage),
      wearScreenShapeProvider
          .overrideWith((_) => WearScreenShape.rectangular),
      eventsProvider.overrideWith((ref) => events),
    ],
    child: const MaterialApp(home: WearScheduleDetailScreen()),
  );
}

void main() {
  group('WearScheduleDetailScreen', () {
    testWidgets('shows day label with date', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      final now = DateTime.now();
      final formatted =
          '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}';
      expect(find.text(formatted), findsOneWidget);
    });

    testWidgets('shows no lessons text when empty', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.text('No lessons'), findsOneWidget);
    });

    testWidgets('shows lesson entries for today', (tester) async {
      await tester.pumpWidget(_buildScreen(events: [
        _event(number: 1),
        _event(id: 2, number: 2, startTime: '09:00:00', endTime: '09:45:00'),
      ]));
      await tester.pump();

      expect(find.text('08:00 - 08:45'), findsOneWidget);
      expect(find.text('09:00 - 09:45'), findsOneWidget);
    });

    testWidgets('shows no chevron icons', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.byIcon(Icons.chevron_left), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });
  });
}
