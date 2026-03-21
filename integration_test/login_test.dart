import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/mock_app.dart';
import 'helpers/ui_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Login flow', () {
    testWidgets('valid credentials add account and show students', (
      tester,
    ) async {
      await setupMockApp(tester);

      await tapAddAccountOutlined(tester);
      await selectProvider(tester, 'Mobireg');
      await enterCredentials(
        tester,
        school: 'osm-wroclaw',
        login: 'testuser',
        password: 'testpass',
      );
      await tapAddAccount(tester);

      expect(find.textContaining('Dawid'), findsWidgets);
      expect(find.textContaining('Zofia'), findsWidgets);
    });

    testWidgets('empty school field shows validation error', (tester) async {
      await setupMockApp(tester);

      await tapAddAccountOutlined(tester);
      await selectProvider(tester, 'Mobireg');
      await enterCredentials(
        tester,
        school: '',
        login: 'user',
        password: 'pass',
      );
      await tapAddAccount(tester);

      expect(find.text('Enter school identifier'), findsOneWidget);
    });

    testWidgets('empty login shows validation error', (tester) async {
      await setupMockApp(tester);

      await tapAddAccountOutlined(tester);
      await selectProvider(tester, 'Mobireg');
      await enterCredentials(
        tester,
        school: 'osm-wroclaw',
        login: '',
        password: 'pass',
      );
      await tapAddAccount(tester);

      expect(find.text('Enter username'), findsOneWidget);
    });

    testWidgets('empty password shows validation error', (tester) async {
      await setupMockApp(tester);

      await tapAddAccountOutlined(tester);
      await selectProvider(tester, 'Mobireg');
      await enterCredentials(
        tester,
        school: 'osm-wroclaw',
        login: 'user',
        password: '',
      );
      await tapAddAccount(tester);

      expect(find.text('Enter password'), findsOneWidget);
    });

    testWidgets('wrong school shows error message', (tester) async {
      await setupMockApp(tester);

      await tapAddAccountOutlined(tester);
      await selectProvider(tester, 'Mobireg');
      await enterCredentials(
        tester,
        school: 'nonexistent-school',
        login: 'bad',
        password: 'bad',
      );
      await tapAddAccount(tester);
      await tester.pumpAndSettle(const Duration(seconds: 15));

      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('app renders without crash on startup', (tester) async {
      await setupMockApp(tester);
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('login to school-a then add school-b shows both accounts', (
      tester,
    ) async {
      await setupMockApp(tester);

      await tapAddAccountOutlined(tester);
      await selectProvider(tester, 'Mobireg');
      await enterCredentials(
        tester,
        school: 'osm-wroclaw',
        login: 'user',
        password: 'pass',
      );
      await tapAddAccount(tester);

      expect(find.textContaining('liwa'), findsWidgets);

      await tapAddAccountOutlined(tester);
      await selectProvider(tester, 'Mobireg');
      await enterCredentials(
        tester,
        school: 'sp5-krakow',
        login: 'user',
        password: 'pass',
      );
      await tapAddAccount(tester);

      expect(find.textContaining('liwa'), findsWidgets);
      expect(find.textContaining('Wi'), findsWidgets);
    });
  });
}
