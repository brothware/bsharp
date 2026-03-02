import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/child_mode_provider.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/presentation/child_mode/screens/child_mode_config_screen.dart';

import '../data/credential_storage_test.dart';

Widget _buildApp({
  ChildModeState? initialState,
  CredentialStorage? storage,
}) {
  final store =
      storage ?? CredentialStorage(store: FakeKeyValueStore());
  return ProviderScope(
    overrides: [
      credentialStorageProvider.overrideWithValue(store),
    ],
    child: const MaterialApp(
      home: ChildModeConfigScreen(),
    ),
  );
}

void main() {
  group('ChildModeConfigScreen', () {
    testWidgets('shows PIN setup when no PIN set', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      expect(find.text('Set PIN'), findsOneWidget);
      expect(
        find.text('Required to enable child mode'),
        findsOneWidget,
      );
    });

    testWidgets('shows feature toggles section', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      expect(find.text('Visible features'), findsOneWidget);
      expect(find.text('Schedule'), findsOneWidget);
      expect(find.text('Grades'), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);
      expect(find.text('Messages'), findsOneWidget);
      expect(find.text('Notes and praise'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('feature toggles use SwitchListTile', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      expect(find.byType(SwitchListTile), findsNWidgets(6));
    });

    testWidgets('has correct section headers', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      expect(find.text('PIN'), findsOneWidget);
      expect(find.text('Visible features'), findsOneWidget);
      expect(find.text('Mode'), findsOneWidget);
    });

    testWidgets('app bar shows correct title', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      expect(find.text('Child mode'), findsOneWidget);
    });

    testWidgets('tapping feature toggle updates config', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      final switchFinder = find.byType(SwitchListTile);
      final messagesSwitch = switchFinder.at(3);
      await tester.tap(messagesSwitch);
      await tester.pump();

      expect(find.byType(SwitchListTile), findsNWidgets(6));
    });
  });
}
