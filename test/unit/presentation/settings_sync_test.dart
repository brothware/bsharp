import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:bsharp/presentation/settings/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/credential_storage_test.dart';

Future<Widget> _buildSettings() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final storage = CredentialStorage(store: FakeKeyValueStore());

  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      credentialStorageProvider.overrideWithValue(storage),
    ],
    child: const MaterialApp(home: SettingsScreen()),
  );
}

void main() {
  group('Settings - Sync Section', () {
    testWidgets('shows sync section header', (tester) async {
      await tester.pumpWidget(await _buildSettings());
      await tester.pump();

      expect(find.text('Synchronisation'), findsOneWidget);
    });

    testWidgets('shows sync now button', (tester) async {
      await tester.pumpWidget(await _buildSettings());
      await tester.pump();

      expect(find.text('Sync now'), findsOneWidget);
    });

    testWidgets('shows sync interval setting', (tester) async {
      await tester.pumpWidget(await _buildSettings());
      await tester.pump();

      expect(find.text('Sync interval'), findsOneWidget);
      expect(find.text('Every 30 minutes'), findsOneWidget);
    });

  });

  group('Settings - Notification Section', () {
    testWidgets('shows notification section header', (tester) async {
      await tester.pumpWidget(await _buildSettings());
      await tester.pump();

      expect(find.text('Notifications'), findsOneWidget);
    });

    testWidgets('shows all notification category toggles', (tester) async {
      await tester.pumpWidget(await _buildSettings());
      await tester.pump();

      expect(find.text('Grades'), findsOneWidget);
      expect(find.text('Schedule'), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);
      expect(find.text('Homework'), findsOneWidget);
      expect(find.text('Notes and praise'), findsOneWidget);
    });

    testWidgets('has SwitchListTile for each category', (tester) async {
      await tester.pumpWidget(await _buildSettings());
      await tester.pump();

      expect(find.byType(SwitchListTile), findsNWidgets(6));
    });
  });
}
