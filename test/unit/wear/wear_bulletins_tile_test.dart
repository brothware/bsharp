import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/domain/entities/portal.dart';
import 'package:bsharp/presentation/more/providers/more_providers.dart';
import 'package:bsharp/wear/screens/wear_bulletins_tile.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';

import '../data/credential_storage_test.dart';

Widget _buildTile({List<PortalBulletin> bulletins = const []}) {
  final storage = CredentialStorage(storage: FakeFlutterSecureStorage());
  return ProviderScope(
    overrides: [
      credentialStorageProvider.overrideWithValue(storage),
      wearScreenShapeProvider
          .overrideWith((_) => WearScreenShape.rectangular),
      bulletinsProvider.overrideWith((ref) => bulletins),
    ],
    child: const MaterialApp(
      home: Scaffold(body: WearBulletinsTile()),
    ),
  );
}

void main() {
  group('WearBulletinsTile', () {
    testWidgets('shows empty state when no bulletins', (tester) async {
      await tester.pumpWidget(_buildTile());
      await tester.pump();

      expect(find.text('No announcements'), findsOneWidget);
      expect(find.byIcon(Icons.campaign_outlined), findsWidgets);
    });

    testWidgets('shows header', (tester) async {
      await tester.pumpWidget(_buildTile());
      await tester.pump();

      expect(find.text('Announcements'), findsOneWidget);
    });

    testWidgets('shows bulletin items', (tester) async {
      await tester.pumpWidget(_buildTile(bulletins: [
        const PortalBulletin(
          id: 1,
          title: 'School Trip',
          content: 'We are going to...',
          date: '2025-06-15',
          author: 'Director',
          isRead: true,
        ),
      ]));
      await tester.pump();

      expect(find.text('School Trip'), findsOneWidget);
      expect(find.text('Director'), findsOneWidget);
    });

    testWidgets('shows unread badge', (tester) async {
      await tester.pumpWidget(_buildTile(bulletins: [
        const PortalBulletin(
          id: 1,
          title: 'Announcement',
          content: 'Text',
          date: '2025-06-15',
          author: 'Admin',
          isRead: false,
        ),
        const PortalBulletin(
          id: 2,
          title: 'Announcement 2',
          content: 'Text',
          date: '2025-06-16',
          author: 'Admin',
          isRead: false,
        ),
      ]));
      await tester.pump();

      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('unread bulletins have bold title', (tester) async {
      await tester.pumpWidget(_buildTile(bulletins: [
        const PortalBulletin(
          id: 1,
          title: 'Unread Item',
          content: 'Text',
          date: '2025-06-15',
          author: 'Admin',
          isRead: false,
        ),
      ]));
      await tester.pump();

      final textWidget = tester.widget<Text>(find.text('Unread Item'));
      expect(textWidget.style?.fontWeight, FontWeight.bold);
    });
  });
}
