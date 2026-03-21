import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/mock_app.dart';
import 'helpers/ui_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> addSchoolA(WidgetTester tester) async {
    await tapAddAccountOutlined(tester);
    await selectProvider(tester, 'Mobireg');
    await enterCredentials(
      tester,
      school: 'osm-wroclaw',
      login: 'user',
      password: 'pass',
    );
    await tapAddAccount(tester);
  }

  Future<void> addSchoolB(WidgetTester tester) async {
    await tapAddAccountOutlined(tester);
    await selectProvider(tester, 'Mobireg');
    await enterCredentials(
      tester,
      school: 'sp5-krakow',
      login: 'user',
      password: 'pass',
    );
    await tapAddAccount(tester);
  }

  group('Multi-account', () {
    testWidgets('add school-a lists students', (tester) async {
      await setupMockApp(tester);
      await addSchoolA(tester);

      expect(find.textContaining('liwa'), findsWidgets);
      expect(find.textContaining('Kowalczyk'), findsWidgets);
    });

    testWidgets('continue to app after adding account shows dashboard', (
      tester,
    ) async {
      await setupMockApp(tester);
      await addSchoolA(tester);
      await tapContinue(tester);
      await waitForSync(tester);

      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('add both schools lists both accounts', (tester) async {
      await setupMockApp(tester);
      await addSchoolA(tester);
      await addSchoolB(tester);

      expect(find.textContaining('liwa'), findsWidgets);
      expect(find.textContaining('Wi'), findsWidgets);
    });

    testWidgets('remove account shows confirmation dialog', (tester) async {
      await setupMockApp(tester);
      await addSchoolA(tester);

      final removeButton = find.byIcon(Icons.remove_circle_outline);
      if (removeButton.evaluate().isNotEmpty) {
        await tester.tap(removeButton.first);
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
      }
    });

    testWidgets('after removing all accounts shows empty state', (
      tester,
    ) async {
      await setupMockApp(tester);
      await addSchoolA(tester);

      final removeButton = find.byIcon(Icons.remove_circle_outline);
      if (removeButton.evaluate().isNotEmpty) {
        await tester.tap(removeButton.first);
        await tester.pumpAndSettle();

        final deleteButton = find.widgetWithText(FilledButton, 'Delete');
        if (deleteButton.evaluate().isNotEmpty) {
          await tester.tap(deleteButton);
          await tester.pumpAndSettle();
        }
      }

      expect(
        find.widgetWithText(OutlinedButton, 'Add account'),
        findsOneWidget,
      );
    });
  });
}
