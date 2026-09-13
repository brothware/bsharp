import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/providers/attendance_providers.dart';
import 'package:bsharp/app/providers/schedule_providers.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/domain/date_utils.dart';
import 'package:bsharp/domain/entities/attendance.dart';
import 'package:bsharp/domain/entities/sync_action.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:bsharp/wear/screens/wear_attendance_detail_screen.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/credential_storage_test.dart';

Widget _buildScreen({
  required SharedPreferences prefs,
  List<Attendance> attendances = const [],
  List<AttendanceType> types = const [],
  WearScreenShape shape = WearScreenShape.rectangular,
  double textScale = 1,
}) {
  final storage = CredentialStorage(store: FakeKeyValueStore());
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      credentialStorageProvider.overrideWithValue(storage),
      wearScreenShapeProvider.overrideWith((_) => shape),
      attendancesProvider.overrideWithBuild((ref, _) => attendances),
      attendanceTypesProvider.overrideWithBuild((ref, _) => types),
      resolvedEventsProvider.overrideWithBuild((ref, _) => []),
    ],
    child: MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: const WearAttendanceDetailScreen(),
    ),
  );
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('WearAttendanceDetailScreen', () {
    testWidgets('shows month label with period selector chevrons', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen(prefs: prefs));
      await tester.pump();

      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('tapping forward changes the month label', (tester) async {
      await tester.pumpWidget(_buildScreen(prefs: prefs));
      await tester.pump();

      final now = DateTime.now();
      final nextMonth = DateTime(now.year, now.month + 1);

      expect(find.text(monthName(now.month)), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pump();

      expect(find.text(monthName(nextMonth.month)), findsOneWidget);
    });

    testWidgets('shows weekday headers', (tester) async {
      await tester.pumpWidget(_buildScreen(prefs: prefs));
      await tester.pump();

      expect(find.text('M'), findsOneWidget);
      expect(find.text('F'), findsOneWidget);
    });

    testWidgets('shows calendar grid', (tester) async {
      await tester.pumpWidget(_buildScreen(prefs: prefs));
      await tester.pump();

      expect(find.byType(SliverGrid), findsOneWidget);
    });

    testWidgets('shows month name label', (tester) async {
      await tester.pumpWidget(_buildScreen(prefs: prefs));
      await tester.pump();

      expect(find.byType(Text), findsWidgets);
      expect(find.byType(SliverGrid), findsOneWidget);
    });

    testWidgets('hides the donut summary when there is no data', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen(prefs: prefs));
      await tester.pump();

      expect(find.textContaining('%'), findsNothing);
    });

    testWidgets('shows a donut summary above the calendar when data exists', (
      tester,
    ) async {
      final types = [
        const AttendanceType(
          id: 1,
          name: 'Present',
          abbr: 'ob',
          countAs: AttendanceCountAs.present,
          excuseStatus: AttendanceExcuseStatus.auto,
        ),
        const AttendanceType(
          id: 2,
          name: 'Absent',
          abbr: 'nb',
          countAs: AttendanceCountAs.absent,
          excuseStatus: AttendanceExcuseStatus.unexcused,
        ),
      ];
      final attendances = [
        const Attendance(id: 1, eventsId: 1, studentsId: 1, typesId: 1),
        const Attendance(id: 2, eventsId: 2, studentsId: 1, typesId: 2),
      ];

      await tester.pumpWidget(
        _buildScreen(prefs: prefs, attendances: attendances, types: types),
      );
      await tester.pump();

      expect(find.byKey(const Key('attendanceDonut')), findsOneWidget);
      expect(find.textContaining('%'), findsOneWidget);

      final donutBottom = tester
          .getBottomLeft(find.byKey(const Key('attendanceDonut')))
          .dy;
      final scrollTop = tester.getTopLeft(find.byType(CustomScrollView)).dy;
      expect(donutBottom, greaterThanOrEqualTo(scrollTop));
    });

    testWidgets(
      'no overflow at 227dp round with data, at normal and 1.3x font scale',
      (tester) async {
        final types = [
          const AttendanceType(
            id: 1,
            name: 'Present',
            abbr: 'ob',
            countAs: AttendanceCountAs.present,
            excuseStatus: AttendanceExcuseStatus.auto,
          ),
          const AttendanceType(
            id: 2,
            name: 'Absent',
            abbr: 'nb',
            countAs: AttendanceCountAs.absent,
            excuseStatus: AttendanceExcuseStatus.unexcused,
          ),
        ];
        final attendances = [
          const Attendance(id: 1, eventsId: 1, studentsId: 1, typesId: 1),
          const Attendance(id: 2, eventsId: 2, studentsId: 1, typesId: 2),
        ];

        tester.view.physicalSize = const Size(227, 227);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        for (final textScale in [1.0, 1.3]) {
          await tester.pumpWidget(
            _buildScreen(
              prefs: prefs,
              attendances: attendances,
              types: types,
              shape: WearScreenShape.round,
              textScale: textScale,
            ),
          );
          await tester.pump();

          expect(
            tester.takeException(),
            isNull,
            reason: 'overflow at textScale $textScale',
          );
        }
      },
    );
  });
}
