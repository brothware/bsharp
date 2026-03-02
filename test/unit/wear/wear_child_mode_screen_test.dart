import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/child_mode_provider.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/wear/screens/wear_child_mode_screen.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';

import '../data/credential_storage_test.dart';

Widget _buildApp({List<Override> overrides = const []}) {
  final storage = CredentialStorage(store: FakeKeyValueStore());
  return ProviderScope(
    overrides: [
      credentialStorageProvider.overrideWithValue(storage),
      wearScreenShapeProvider.overrideWith((_) => WearScreenShape.rectangular),
      ...overrides,
    ],
    child: const MaterialApp(home: WearChildModeScreen()),
  );
}

Future<Widget> _buildAppWithPin() async {
  final fakeSecure = FakeKeyValueStore();
  await fakeSecure.write(key: 'child_mode_pin', value: '1234');
  final storage = CredentialStorage(store: fakeSecure);
  return ProviderScope(
    overrides: [
      credentialStorageProvider.overrideWithValue(storage),
      wearScreenShapeProvider.overrideWith((_) => WearScreenShape.rectangular),
    ],
    child: const MaterialApp(home: WearChildModeScreen()),
  );
}

void main() {
  group('WearChildModeScreen', () {
    testWidgets('shows Set PIN when no PIN set', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      expect(find.text('Child mode'), findsOneWidget);
      expect(find.text('Set PIN'), findsOneWidget);
      expect(find.byIcon(Icons.child_care), findsOneWidget);
    });

    testWidgets('shows PIN management items when PIN set', (tester) async {
      await tester.pumpWidget(await _buildAppWithPin());
      await tester.pump();
      await tester.pump();

      expect(find.text('PIN set'), findsOneWidget);
      expect(find.text('Change PIN'), findsOneWidget);
      expect(find.text('Remove PIN'), findsAtLeast(1));
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('shows feature toggles when PIN set', (tester) async {
      await tester.pumpWidget(await _buildAppWithPin());
      await tester.pump();
      await tester.pump();

      expect(find.text('Schedule'), findsOneWidget);
      expect(find.text('Grades'), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);
      expect(find.text('Messages'), findsOneWidget);
      expect(find.text('Notes'), findsAtLeast(1));
      expect(find.text('Settings'), findsOneWidget);
      expect(find.byType(Switch), findsNWidgets(6));
    });

    testWidgets('does not show toggles when no PIN set', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      expect(find.byType(Switch), findsNothing);
    });

    testWidgets('shows enable child mode button when in parent mode',
        (tester) async {
      await tester.pumpWidget(await _buildAppWithPin());
      await tester.pump();
      await tester.pump();

      expect(find.text('Enable child mode'), findsOneWidget);
    });

    testWidgets('remove PIN shows confirmation dialog', (tester) async {
      await tester.pumpWidget(await _buildAppWithPin());
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Remove PIN').first);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Remove PIN'), findsAtLeast(1));
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('confirming remove PIN clears PIN state', (tester) async {
      await tester.pumpWidget(await _buildAppWithPin());
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Remove PIN').first);
      await tester.pumpAndSettle();

      final dialogRemoveButtons = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Remove PIN'),
      );
      await tester.tap(dialogRemoveButtons.last);
      await tester.pumpAndSettle();

      final element = tester.element(find.byType(WearChildModeScreen));
      final container = ProviderScope.containerOf(element);
      expect(container.read(childModeProvider).isPinSet, isFalse);
    });

    testWidgets('toggle changes config', (tester) async {
      await tester.pumpWidget(await _buildAppWithPin());
      await tester.pump();
      await tester.pump();

      final switches = find.byType(Switch);
      final scheduleSwitch = switches.at(0);
      await tester.tap(scheduleSwitch);
      await tester.pump();

      final element = tester.element(find.byType(WearChildModeScreen));
      final container = ProviderScope.containerOf(element);
      expect(
        container.read(childModeProvider).config.scheduleVisible,
        isFalse,
      );
    });
  });
}
