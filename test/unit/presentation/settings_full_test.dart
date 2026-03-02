import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:bsharp/presentation/settings/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/credential_storage_test.dart';

Future<Widget> _buildSettings({String? locale}) async {
  final initial = locale != null ? {'locale': locale} : <String, Object>{};
  SharedPreferences.setMockInitialValues(initial);
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

Future<void> _scrollTo(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(find.text(text), 300);
}

void main() {
  group('Settings - Appearance Section', () {
    testWidgets('shows appearance section header', (tester) async {
      await tester.pumpWidget(await _buildSettings());
      await tester.pump();

      expect(find.text('Appearance'), findsOneWidget);
    });

    testWidgets('shows theme setting', (tester) async {
      await tester.pumpWidget(await _buildSettings());
      await tester.pump();

      expect(find.text('Theme'), findsOneWidget);
    });

    testWidgets('shows language setting with System default', (tester) async {
      await tester.pumpWidget(await _buildSettings());
      await tester.pump();

      expect(find.text('Language'), findsOneWidget);
      expect(find.text('System'), findsAtLeast(1));
    });

    testWidgets('tapping theme opens dialog', (tester) async {
      await tester.pumpWidget(await _buildSettings());
      await tester.pump();

      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();

      expect(find.text('Choose theme'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
    });

    testWidgets('tapping language opens dialog', (tester) async {
      await tester.pumpWidget(await _buildSettings());
      await tester.pump();

      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();

      expect(find.text('Choose language'), findsOneWidget);
      expect(find.text('System'), findsAtLeast(1));
      expect(find.text('English'), findsAtLeast(1));
    });
  });

  group('Settings - Child Mode Section', () {
    testWidgets('shows child mode section', (tester) async {
      await tester.pumpWidget(await _buildSettings());
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Child mode configuration'),
        200,
      );

      expect(find.text('Child mode configuration'), findsOneWidget);
    });
  });

  group('Settings - Account Section', () {
    testWidgets('shows change password option', (tester) async {
      await tester.pumpWidget(await _buildSettings());
      await tester.pump();
      await tester.scrollUntilVisible(find.text('Change password'), 200);

      expect(find.text('Change password'), findsOneWidget);
    });

    testWidgets('shows logout option', (tester) async {
      await tester.pumpWidget(await _buildSettings());
      await tester.pump();
      await tester.scrollUntilVisible(find.text('Log out'), 200);

      expect(find.text('Log out'), findsOneWidget);
    });

    testWidgets('tapping logout shows confirmation dialog', (tester) async {
      await tester.pumpWidget(await _buildSettings());
      await tester.pump();
      await tester.scrollUntilVisible(find.text('Log out'), 200);

      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();

      expect(
        find.text('Are you sure you want to log out? '
            'Saved data will be deleted.'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Log out'), findsAtLeast(2));
    });

    testWidgets('tapping change password opens dialog', (tester) async {
      await tester.pumpWidget(await _buildSettings());
      await tester.pump();
      await tester.scrollUntilVisible(find.text('Change password'), 200);

      await tester.tap(find.text('Change password'));
      await tester.pumpAndSettle();

      expect(find.text('Current password'), findsOneWidget);
      expect(find.text('New password'), findsOneWidget);
      expect(find.text('Repeat new password'), findsOneWidget);
    });
  });

  group('Settings - Data Section', () {
    testWidgets('shows clear cache option', (tester) async {
      await tester.pumpWidget(await _buildSettings());
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Clear cache'),
        200,
      );

      expect(find.text('Clear cache'), findsOneWidget);
    });

    testWidgets('tapping clear cache shows confirmation', (tester) async {
      await tester.pumpWidget(await _buildSettings());
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Clear cache'),
        200,
      );

      await tester.tap(find.text('Clear cache'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Are you sure you want to delete'),
        findsOneWidget,
      );
      expect(find.text('Clear'), findsOneWidget);
    });
  });

  group('Settings - About Section', () {
    testWidgets('shows app name and version', (tester) async {
      await tester.pumpWidget(await _buildSettings());
      await tester.pump();
      await _scrollTo(tester, 'BSharp');

      expect(find.text('BSharp'), findsOneWidget);
      expect(find.text('Version 0.1.0'), findsOneWidget);
    });

    testWidgets('shows licenses option', (tester) async {
      await tester.pumpWidget(await _buildSettings());
      await tester.pump();
      await _scrollTo(tester, 'BSharp');

      expect(find.text('Licences'), findsOneWidget);
    });

    testWidgets('shows source code link', (tester) async {
      await tester.pumpWidget(await _buildSettings());
      await tester.pump();
      await _scrollTo(tester, 'BSharp');

      expect(find.text('Source code'), findsOneWidget);
      expect(find.text('GitHub'), findsOneWidget);
    });
  });
}
