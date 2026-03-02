import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/domain/entities/portal.dart';
import 'package:bsharp/presentation/more/providers/more_providers.dart';
import 'package:bsharp/wear/screens/wear_homework_detail_screen.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';

import '../data/credential_storage_test.dart';

Widget _buildScreen({List<PortalHomework> homework = const []}) {
  final storage = CredentialStorage(store: FakeKeyValueStore());
  return ProviderScope(
    overrides: [
      credentialStorageProvider.overrideWithValue(storage),
      wearScreenShapeProvider
          .overrideWith((_) => WearScreenShape.rectangular),
      homeworksProvider.overrideWith((ref) => homework),
    ],
    child: const MaterialApp(home: WearHomeworkDetailScreen()),
  );
}

void main() {
  group('WearHomeworkDetailScreen', () {
    testWidgets('shows filter selector', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('shows empty state', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.text('No homework'), findsOneWidget);
    });

    testWidgets('cycles filter on chevron tap', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.text('Upcoming'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pump();

      expect(find.text('Past'), findsOneWidget);
    });

    testWidgets('shows homework details', (tester) async {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final dateStr =
          '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
      await tester.pumpWidget(_buildScreen(homework: [
        PortalHomework(
          id: 1,
          subjectName: 'English',
          date: '2025-01-10',
          dueDate: dateStr,
          content: 'Write an essay about nature',
        ),
      ]));
      await tester.pump();

      expect(find.text('English'), findsOneWidget);
      expect(find.text('Write an essay about nature'), findsOneWidget);
    });
  });
}
