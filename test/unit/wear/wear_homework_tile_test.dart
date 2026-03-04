import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/domain/entities/portal.dart';
import 'package:bsharp/presentation/more/providers/more_providers.dart';
import 'package:bsharp/wear/screens/wear_homework_tile.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../data/credential_storage_test.dart';

Widget _buildTile({List<PortalHomework> homework = const []}) {
  final storage = CredentialStorage(store: FakeKeyValueStore());
  return ProviderScope(
    overrides: [
      credentialStorageProvider.overrideWithValue(storage),
      wearScreenShapeProvider.overrideWith((_) => WearScreenShape.rectangular),
      homeworksProvider.overrideWithBuild((ref, _) => homework),
    ],
    child: const MaterialApp(home: Scaffold(body: WearHomeworkTile())),
  );
}

void main() {
  group('WearHomeworkTile', () {
    testWidgets('shows empty state when no homework', (tester) async {
      await tester.pumpWidget(_buildTile());
      await tester.pump();

      expect(find.text('No homework'), findsOneWidget);
      expect(find.byIcon(Icons.assignment_outlined), findsOneWidget);
    });

    testWidgets('shows homework header', (tester) async {
      await tester.pumpWidget(_buildTile());
      await tester.pump();

      expect(find.text('Homework'), findsOneWidget);
      expect(find.byIcon(Icons.assignment), findsOneWidget);
    });

    testWidgets('shows upcoming homework items', (tester) async {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final dateStr =
          '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
      await tester.pumpWidget(
        _buildTile(
          homework: [
            PortalHomework(
              id: 1,
              subjectName: 'Mathematics',
              date: '2025-01-01',
              dueDate: dateStr,
              content: 'Solve exercises 1-5',
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.text('Mathematics'), findsOneWidget);
      expect(find.text('Solve exercises 1-5'), findsOneWidget);
    });

    testWidgets('uses NeverScrollableScrollPhysics on list', (tester) async {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final dateStr =
          '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
      await tester.pumpWidget(
        _buildTile(
          homework: [
            PortalHomework(
              id: 1,
              subjectName: 'Math',
              date: '2025-01-01',
              dueDate: dateStr,
              content: 'Task',
            ),
          ],
        ),
      );
      await tester.pump();

      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.physics, isA<NeverScrollableScrollPhysics>());
    });
  });
}
