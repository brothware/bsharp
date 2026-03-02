import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/domain/entities/portal.dart';
import 'package:bsharp/presentation/more/providers/more_providers.dart';
import 'package:bsharp/wear/screens/wear_notes_tile.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';

import '../data/credential_storage_test.dart';

Widget _buildTile({List<PortalReprimand> reprimands = const []}) {
  final storage = CredentialStorage(store: FakeKeyValueStore());
  return ProviderScope(
    overrides: [
      credentialStorageProvider.overrideWithValue(storage),
      wearScreenShapeProvider
          .overrideWith((_) => WearScreenShape.rectangular),
      reprimandsProvider.overrideWith((ref) => reprimands),
    ],
    child: const MaterialApp(
      home: Scaffold(body: WearNotesTile()),
    ),
  );
}

void main() {
  group('WearNotesTile', () {
    testWidgets('shows empty state when no notes', (tester) async {
      await tester.pumpWidget(_buildTile());
      await tester.pump();

      expect(find.text('No notes'), findsOneWidget);
      expect(find.byIcon(Icons.sticky_note_2_outlined), findsWidgets);
    });

    testWidgets('shows header', (tester) async {
      await tester.pumpWidget(_buildTile());
      await tester.pump();

      expect(find.text('Notes and praise'), findsOneWidget);
    });

    testWidgets('shows note items with warning icon', (tester) async {
      await tester.pumpWidget(_buildTile(reprimands: [
        const PortalReprimand(
          id: 1,
          date: '2025-01-15',
          teacherName: 'Jan Kowalski',
          content: 'Forgot homework',
          type: 0,
        ),
      ]));
      await tester.pump();

      expect(find.text('Forgot homework'), findsOneWidget);
      expect(find.text('Jan Kowalski'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber), findsOneWidget);
    });

    testWidgets('shows praise items with trophy icon', (tester) async {
      await tester.pumpWidget(_buildTile(reprimands: [
        const PortalReprimand(
          id: 1,
          date: '2025-01-15',
          teacherName: 'Anna Nowak',
          content: 'Excellent presentation',
          type: 1,
        ),
      ]));
      await tester.pump();

      expect(find.text('Excellent presentation'), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
    });

    testWidgets('uses NeverScrollableScrollPhysics on list', (tester) async {
      await tester.pumpWidget(_buildTile(reprimands: [
        const PortalReprimand(
          id: 1,
          date: '2025-01-15',
          teacherName: 'T',
          content: 'C',
          type: 0,
        ),
      ]));
      await tester.pump();

      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.physics, isA<NeverScrollableScrollPhysics>());
    });
  });
}
