import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/domain/entities/portal.dart';
import 'package:bsharp/wear/screens/wear_bulletin_detail_screen.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';

import '../data/credential_storage_test.dart';

Widget _buildScreen({required PortalBulletin bulletin}) {
  final storage = CredentialStorage(store: FakeKeyValueStore());
  return ProviderScope(
    overrides: [
      credentialStorageProvider.overrideWithValue(storage),
      wearScreenShapeProvider
          .overrideWith((_) => WearScreenShape.rectangular),
    ],
    child: MaterialApp(
      home: WearBulletinDetailScreen(bulletin: bulletin),
    ),
  );
}

void main() {
  group('WearBulletinDetailScreen', () {
    testWidgets('shows bulletin title', (tester) async {
      await tester.pumpWidget(
        _buildScreen(
          bulletin: const PortalBulletin(
            id: 1,
            title: 'Important Announcement',
            content: 'Details here...',
            date: '2025-06-15',
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
          bulletin: const PortalBulletin(
            id: 1,
            title: 'Test',
            content: 'Content',
            date: '2025-06-15',
            author: 'School Director',
            isRead: true,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('School Director'), findsOneWidget);
      expect(find.text('2025-06-15'), findsOneWidget);
    });

    testWidgets('shows content text', (tester) async {
      await tester.pumpWidget(
        _buildScreen(
          bulletin: const PortalBulletin(
            id: 1,
            title: 'Title',
            content: 'This is the full content of the announcement.',
            date: '2025-06-15',
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
