import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/domain/entities/portal.dart';
import 'package:bsharp/wear/screens/wear_bulletin_detail_screen.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../data/credential_storage_test.dart';

Widget _buildScreen({required PortalBulletin bulletin}) {
  final storage = CredentialStorage(store: FakeKeyValueStore());
  return ProviderScope(
    overrides: [
      credentialStorageProvider.overrideWithValue(storage),
      wearScreenShapeProvider.overrideWith((_) => WearScreenShape.rectangular),
    ],
    child: MaterialApp(home: WearBulletinDetailScreen(bulletin: bulletin)),
  );
}

void main() {
  group('WearBulletinDetailScreen', () {
    testWidgets('shows bulletin title', (tester) async {
      await tester.pumpWidget(
        _buildScreen(
          bulletin: PortalBulletin(
            id: 1,
            title: 'Important Announcement',
            content: 'Details here...',
            date: DateTime(2025, 6, 15, 9, 5),
            author: 'School Director',
            isRead: true,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Important Announcement'), findsOneWidget);
    });

    testWidgets('shows author and date', (tester) async {
      await tester.pumpWidget(
        _buildScreen(
          bulletin: PortalBulletin(
            id: 1,
            title: 'Test',
            content: 'Content',
            date: DateTime(2025, 6, 15, 9, 5),
            author: 'School Director',
            isRead: true,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('School Director'), findsOneWidget);
      expect(find.text('15.06.2025 09:05'), findsOneWidget);
    });

    testWidgets('title scrolls out of view with the content', (tester) async {
      await tester.pumpWidget(
        _buildScreen(
          bulletin: PortalBulletin(
            id: 1,
            title: 'Important Announcement',
            content: List.filled(1000, 'Long bulletin line.').join(' '),
            date: DateTime(2025, 6, 15, 9, 5),
            author: 'School Director',
            isRead: true,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Important Announcement'), findsOneWidget);

      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -2000),
      );
      await tester.pump();

      expect(
        find.text('Important Announcement').hitTestable(),
        findsNothing,
      );
    });

    testWidgets('shows content text', (tester) async {
      await tester.pumpWidget(
        _buildScreen(
          bulletin: PortalBulletin(
            id: 1,
            title: 'Title',
            content: 'This is the full content of the announcement.',
            date: DateTime(2025, 6, 15, 9, 5),
            author: 'Admin',
            isRead: true,
          ),
        ),
      );
      await tester.pump();

      expect(
        find.text('This is the full content of the announcement.'),
        findsOneWidget,
      );
    });
  });
}
