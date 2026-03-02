import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/domain/entities/portal.dart';
import 'package:bsharp/presentation/more/providers/more_providers.dart';
import 'package:bsharp/wear/screens/wear_tests_tile.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';

import '../data/credential_storage_test.dart';

Widget _buildTile({List<PortalTest> tests = const []}) {
  final storage = CredentialStorage(store: FakeKeyValueStore());
  return ProviderScope(
    overrides: [
      credentialStorageProvider.overrideWithValue(storage),
      wearScreenShapeProvider
          .overrideWith((_) => WearScreenShape.rectangular),
      testsProvider.overrideWith((ref) => tests),
    ],
    child: const MaterialApp(
      home: Scaffold(body: WearTestsTile()),
    ),
  );
}

void main() {
  group('WearTestsTile', () {
    testWidgets('shows empty state when no tests', (tester) async {
      await tester.pumpWidget(_buildTile());
      await tester.pump();

      expect(find.text('No tests'), findsOneWidget);
      expect(find.byIcon(Icons.quiz_outlined), findsWidgets);
    });

    testWidgets('shows header', (tester) async {
      await tester.pumpWidget(_buildTile());
      await tester.pump();

      expect(find.text('Tests'), findsOneWidget);
    });

    testWidgets('shows upcoming test items', (tester) async {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final dateStr =
          '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
      await tester.pumpWidget(_buildTile(tests: [
        PortalTest(
          id: 1,
          subjectName: 'Physics',
          date: dateStr,
          title: 'Chapter 5 test',
        ),
      ]));
      await tester.pump();

      expect(find.text('Physics'), findsOneWidget);
      expect(find.text('Chapter 5 test'), findsOneWidget);
    });

    testWidgets('uses NeverScrollableScrollPhysics on list', (tester) async {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final dateStr =
          '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
      await tester.pumpWidget(_buildTile(tests: [
        PortalTest(id: 1, subjectName: 'Math', date: dateStr),
      ]));
      await tester.pump();

      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.physics, isA<NeverScrollableScrollPhysics>());
    });
  });
}
