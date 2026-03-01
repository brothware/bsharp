import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/translation_provider.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/domain/entities/portal.dart';
import 'package:bsharp/presentation/more/providers/more_providers.dart';
import 'package:bsharp/wear/screens/wear_notes_detail_screen.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';

import '../data/credential_storage_test.dart';

Widget _buildScreen({List<PortalReprimand> reprimands = const []}) {
  final storage = CredentialStorage(storage: FakeFlutterSecureStorage());
  return ProviderScope(
    overrides: [
      credentialStorageProvider.overrideWithValue(storage),
      wearScreenShapeProvider
          .overrideWith((_) => WearScreenShape.rectangular),
      reprimandsProvider.overrideWith((ref) => reprimands),
      isTranslationAvailableProvider.overrideWithValue(false),
    ],
    child: const MaterialApp(home: WearNotesDetailScreen()),
  );
}

void main() {
  group('WearNotesDetailScreen', () {
    testWidgets('shows Notes/Praise tab selector', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('Praise'), findsOneWidget);
    });

    testWidgets('shows notes by default', (tester) async {
      await tester.pumpWidget(_buildScreen(reprimands: [
        const PortalReprimand(
          id: 1,
          date: '2025-01-15',
          teacherName: 'Jan K.',
          content: 'Disrupted class',
          type: 0,
        ),
      ]));
      await tester.pump();

      expect(find.text('Disrupted class'), findsOneWidget);
    });

    testWidgets('switches to praise tab', (tester) async {
      await tester.pumpWidget(_buildScreen(reprimands: [
        const PortalReprimand(
          id: 1,
          date: '2025-01-15',
          teacherName: 'Jan K.',
          content: 'Disrupted class',
          type: 0,
        ),
        const PortalReprimand(
          id: 2,
          date: '2025-01-15',
          teacherName: 'Anna N.',
          content: 'Great work',
          type: 1,
        ),
      ]));
      await tester.pump();

      expect(find.text('Disrupted class'), findsOneWidget);
      expect(find.text('Great work'), findsNothing);

      await tester.tap(find.text('Praise'));
      await tester.pump();

      expect(find.text('Great work'), findsOneWidget);
      expect(find.text('Disrupted class'), findsNothing);
    });

    testWidgets('shows empty state for empty tab', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.text('No notes'), findsOneWidget);
    });
  });
}
