import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/domain/entities/portal.dart';
import 'package:bsharp/presentation/more/providers/more_providers.dart';
import 'package:bsharp/wear/screens/wear_tests_detail_screen.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';

import '../data/credential_storage_test.dart';

Widget _buildScreen({List<PortalTest> tests = const []}) {
  final storage = CredentialStorage(store: FakeKeyValueStore());
  return ProviderScope(
    overrides: [
      credentialStorageProvider.overrideWithValue(storage),
      wearScreenShapeProvider
          .overrideWith((_) => WearScreenShape.rectangular),
      testsProvider.overrideWith((ref) => tests),
    ],
    child: const MaterialApp(home: WearTestsDetailScreen()),
  );
}

void main() {
  group('WearTestsDetailScreen', () {
    testWidgets('shows header', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.text('Tests'), findsOneWidget);
    });

    testWidgets('shows empty state', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.text('No tests'), findsOneWidget);
    });

    testWidgets('shows all tests sorted by date', (tester) async {
      await tester.pumpWidget(_buildScreen(tests: [
        const PortalTest(
          id: 1,
          subjectName: 'History',
          date: '2025-01-15',
          title: 'WWII test',
        ),
        const PortalTest(
          id: 2,
          subjectName: 'Biology',
          date: '2025-02-20',
          description: 'Cells and tissues',
        ),
      ]));
      await tester.pump();

      expect(find.text('History'), findsOneWidget);
      expect(find.text('Biology'), findsOneWidget);
      expect(find.text('WWII test'), findsOneWidget);
      expect(find.text('Cells and tissues'), findsOneWidget);
    });
  });
}
