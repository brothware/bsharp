import 'dart:convert';

import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/providers/dashboard_providers.dart';
import 'package:bsharp/app/providers/schedule_providers.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/domain/entities/resolved_event.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:bsharp/wear/screens/wear_dashboard.dart';
import 'package:bsharp/wear/screens/wear_home.dart';
import 'package:bsharp/wear/screens/wear_schedule_detail_screen.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:bsharp/wear/widgets/wear_launcher_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/credential_storage_test.dart';

Future<Widget> _buildApp({
  List<Object> extraOverrides = const [],
  WearScreenShape shape = WearScreenShape.rectangular,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final storage = CredentialStorage(store: FakeKeyValueStore());
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      credentialStorageProvider.overrideWithValue(storage),
      wearScreenShapeProvider.overrideWith((_) => shape),
      ...extraOverrides.cast(),
    ],
    child: const MaterialApp(home: WearHome()),
  );
}

Future<Widget> _buildChildModeApp(Map<String, bool> config) async {
  final fakeSecure = FakeKeyValueStore();
  await fakeSecure.write(key: 'child_mode_pin', value: '1234');
  await fakeSecure.write(key: 'child_mode_active', value: 'true');
  await fakeSecure.write(key: 'child_mode_config', value: jsonEncode(config));
  final storage = CredentialStorage(store: fakeSecure);

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      credentialStorageProvider.overrideWithValue(storage),
      wearScreenShapeProvider.overrideWith((_) => WearScreenShape.rectangular),
    ],
    child: const MaterialApp(home: WearHome()),
  );
}

void main() {
  group('WearHome', () {
    testWidgets('shows the dashboard above one row per visible section', (
      tester,
    ) async {
      await tester.pumpWidget(await _buildApp());
      await tester.pump();

      expect(find.byType(WearDashboard), findsOneWidget);
      expect(find.byType(WearLauncherRow), findsNWidgets(9));

      final dashboardTop = tester.getTopLeft(find.byType(WearDashboard)).dy;
      final firstRowTop = tester
          .getTopLeft(find.byType(WearLauncherRow).first)
          .dy;
      expect(dashboardTop, lessThan(firstRowTop));
    });

    testWidgets('tapping a row opens its section', (tester) async {
      await tester.pumpWidget(await _buildApp());
      await tester.pump();

      await tester.tap(find.text('Schedule'));
      await tester.pumpAndSettle();

      expect(find.byType(WearScheduleDetailScreen), findsOneWidget);
    });

    testWidgets('every row is at least 48dp tall', (tester) async {
      await tester.pumpWidget(await _buildApp());
      await tester.pump();

      for (final element in tester.widgetList<WearLauncherRow>(
        find.byType(WearLauncherRow),
      )) {
        final size = tester.getSize(find.byWidget(element));
        expect(size.height, greaterThanOrEqualTo(48));
      }
    });

    testWidgets('child mode hides filtered sections', (tester) async {
      await tester.pumpWidget(
        await _buildChildModeApp({
          'scheduleVisible': true,
          'gradesVisible': false,
          'attendanceVisible': false,
          'messagesVisible': false,
          'settingsVisible': false,
          'notesVisible': true,
        }),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Schedule'), findsOneWidget);
      expect(find.text('Grades'), findsNothing);
      expect(find.text('Attendance'), findsNothing);
      expect(find.text('Messages'), findsNothing);
    });

    testWidgets('child mode with everything hidden still shows fixed rows', (
      tester,
    ) async {
      await tester.pumpWidget(
        await _buildChildModeApp({
          'scheduleVisible': false,
          'gradesVisible': false,
          'attendanceVisible': false,
          'messagesVisible': false,
          'settingsVisible': false,
          'notesVisible': false,
        }),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(WearLauncherRow), findsNWidgets(4));
      expect(find.text('Homework'), findsOneWidget);
      expect(find.text('Tests'), findsOneWidget);
      expect(find.text('Announcements'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('parent mode shows all sections', (tester) async {
      await tester.pumpWidget(await _buildApp());
      await tester.pump();

      expect(find.byType(WearLauncherRow), findsNWidgets(9));
    });

    testWidgets(
      'a long Polish hero does not push the first row off screen',
      (tester) async {
        const screenSize = Size(227, 227);
        tester.view.physicalSize = const Size(454, 454);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final storage = CredentialStorage(store: FakeKeyValueStore());
        final monday = _nextMonday();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              credentialStorageProvider.overrideWithValue(storage),
              wearScreenShapeProvider.overrideWith(
                (_) => WearScreenShape.round,
              ),
              minuteTickProvider.overrideWith((ref) => monday),
              resolvedEventsProvider.overrideWithBuild(
                (ref, _) => [
                  ResolvedEvent(
                    id: 1,
                    date: monday,
                    number: 1,
                    startTime: '08:50:00',
                    endTime: '09:35:00',
                    subjectName: 'Bardzo długa nazwa lekcji wychowawczej',
                  ),
                ],
              ),
            ],
            child: const MaterialApp(home: WearHome()),
          ),
        );
        await tester.pump();
        await tester.pump();

        final firstRowTop = tester
            .getTopLeft(find.byType(WearLauncherRow).first)
            .dy;
        const peek = 24.0;

        expect(
          firstRowTop,
          lessThan(screenSize.height - peek),
          reason:
              'the first launcher row starts at y=$firstRowTop, leaving less '
              'than ${peek}dp of it on a ${screenSize.height}dp screen. The '
              'dashboard sits a little high of centre so that row shows: '
              'nothing below the fold says the launcher is there',
        );
      },
    );

    testWidgets(
      'the last launcher row can reach the viewport centre when scrolled',
      (tester) async {
        tester.view.physicalSize = const Size(454, 454);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          await _buildApp(shape: WearScreenShape.round),
        );
        await tester.pump();
        await tester.pump();

        final scrollableFinder = find.byType(Scrollable);
        final scrollable = tester
            .widgetList<Scrollable>(scrollableFinder)
            .first;
        final controller = scrollable.controller!;
        for (var i = 0; i < 10; i++) {
          controller.jumpTo(controller.position.maxScrollExtent);
          await tester.pump();
        }
        await tester.pump();

        final viewportTop = tester.getTopLeft(find.byType(CustomScrollView)).dy;
        final viewportHeight = tester
            .getSize(find.byType(CustomScrollView))
            .height;
        final lastRowCenter = tester
            .getCenter(find.byType(WearLauncherRow).last)
            .dy;
        final viewportCenter = viewportTop + viewportHeight / 2;

        expect(
          (lastRowCenter - viewportCenter).abs(),
          lessThan(6),
          reason:
              'the last launcher row centre is at y=$lastRowCenter, the '
              'viewport centre is at y=$viewportCenter, they should '
              'nearly coincide once the list is fully scrolled',
        );
      },
    );
  });
}

DateTime _nextMonday() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final daysUntilMonday = (8 - today.weekday) % 7;
  final offset = daysUntilMonday == 0 ? 7 : daysUntilMonday;
  return today.add(Duration(days: offset));
}
