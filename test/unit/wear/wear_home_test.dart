import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/wear/screens/wear_home.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:bsharp/wear/widgets/wear_page_indicator.dart';

import '../data/credential_storage_test.dart';

Widget _buildApp({List<Override> overrides = const []}) {
  final storage = CredentialStorage(storage: FakeFlutterSecureStorage());
  return ProviderScope(
    overrides: [
      credentialStorageProvider.overrideWithValue(storage),
      wearScreenShapeProvider
          .overrideWith((_) => WearScreenShape.rectangular),
      ...overrides,
    ],
    child: const MaterialApp(home: WearHome()),
  );
}

void main() {
  group('WearHome', () {
    testWidgets('renders PageView with page indicator', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      expect(find.byType(PageView), findsOneWidget);
      expect(find.byType(WearPageIndicator), findsOneWidget);
    });

    testWidgets('first page is schedule tile', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('can swipe to grades tile', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      await tester.drag(find.byType(PageView), const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.text('Grades'), findsOneWidget);
    });

    testWidgets('can swipe to attendance tile', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      await tester.drag(find.byType(PageView), const Offset(0, -500));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(PageView), const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.text('Attendance'), findsOneWidget);
    });

    testWidgets('can swipe to homework tile', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      for (var i = 0; i < 3; i++) {
        await tester.drag(find.byType(PageView), const Offset(0, -500));
        await tester.pumpAndSettle();
      }

      expect(find.text('Homework'), findsOneWidget);
    });

    testWidgets('can swipe to tests tile', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      for (var i = 0; i < 4; i++) {
        await tester.drag(find.byType(PageView), const Offset(0, -500));
        await tester.pumpAndSettle();
      }

      expect(find.text('Tests'), findsOneWidget);
    });

    testWidgets('can swipe to notes tile', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      for (var i = 0; i < 5; i++) {
        await tester.drag(find.byType(PageView), const Offset(0, -500));
        await tester.pumpAndSettle();
      }

      expect(find.text('Notes and praise'), findsOneWidget);
    });

    testWidgets('settings tile shows child mode toggle when PIN set',
        (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      for (var i = 0; i < 8; i++) {
        await tester.drag(find.byType(PageView), const Offset(0, -500));
        await tester.pumpAndSettle();
      }

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Sync'), findsOneWidget);
    });

    testWidgets('child mode hides filtered tiles', (tester) async {
      final fakeSecure = FakeFlutterSecureStorage();
      await fakeSecure.write(key: 'child_mode_pin', value: '1234');
      await fakeSecure.write(key: 'child_mode_active', value: 'true');
      await fakeSecure.write(
        key: 'child_mode_config',
        value: jsonEncode({
          'scheduleVisible': true,
          'gradesVisible': false,
          'attendanceVisible': false,
          'messagesVisible': false,
          'settingsVisible': false,
          'notesVisible': true,
        }),
      );
      final storage = CredentialStorage(storage: fakeSecure);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            credentialStorageProvider.overrideWithValue(storage),
            wearScreenShapeProvider
                .overrideWith((_) => WearScreenShape.rectangular),
          ],
          child: const MaterialApp(home: WearHome()),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byIcon(Icons.calendar_today), findsOneWidget);

      await tester.drag(find.byType(PageView), const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.text('Homework'), findsOneWidget);
    });

    testWidgets('child mode with all features hidden shows new tiles + settings',
        (tester) async {
      final fakeSecure = FakeFlutterSecureStorage();
      await fakeSecure.write(key: 'child_mode_pin', value: '1234');
      await fakeSecure.write(key: 'child_mode_active', value: 'true');
      await fakeSecure.write(
        key: 'child_mode_config',
        value: jsonEncode({
          'scheduleVisible': false,
          'gradesVisible': false,
          'attendanceVisible': false,
          'messagesVisible': false,
          'settingsVisible': false,
          'notesVisible': false,
        }),
      );
      final storage = CredentialStorage(storage: fakeSecure);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            credentialStorageProvider.overrideWithValue(storage),
            wearScreenShapeProvider
                .overrideWith((_) => WearScreenShape.rectangular),
          ],
          child: const MaterialApp(home: WearHome()),
        ),
      );
      await tester.pump();
      await tester.pump();

      final indicator = tester.widget<WearPageIndicator>(
        find.byType(WearPageIndicator),
      );
      expect(indicator.count, 4);
    });

    testWidgets('parent mode shows all tiles', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      final indicator = tester.widget<WearPageIndicator>(
        find.byType(WearPageIndicator),
      );
      expect(indicator.count, 9);
    });
  });
}
