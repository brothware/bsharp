import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/domain/entities/attendance.dart';
import 'package:bsharp/domain/entities/sync_action.dart';
import 'package:bsharp/presentation/attendance/providers/attendance_providers.dart';
import 'package:bsharp/presentation/schedule/providers/schedule_providers.dart';
import 'package:bsharp/wear/screens/wear_attendance_tile.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';

import '../data/credential_storage_test.dart';

Widget _buildTile({
  List<Attendance> attendances = const [],
  List<AttendanceType> types = const [],
}) {
  final storage = CredentialStorage(store: FakeKeyValueStore());
  return ProviderScope(
    overrides: [
      credentialStorageProvider.overrideWithValue(storage),
      wearScreenShapeProvider
          .overrideWith((_) => WearScreenShape.rectangular),
      attendancesProvider.overrideWith((ref) => attendances),
      attendanceTypesProvider.overrideWith((ref) => types),
      eventsProvider.overrideWith((ref) => []),
    ],
    child: const MaterialApp(
      home: Scaffold(body: WearAttendanceTile()),
    ),
  );
}

void main() {
  group('WearAttendanceTile', () {
    testWidgets('shows empty state when no data', (tester) async {
      await tester.pumpWidget(_buildTile());
      await tester.pump();

      expect(find.text('No data'), findsOneWidget);
      expect(find.byIcon(Icons.event_available_outlined), findsOneWidget);
    });

    testWidgets('shows donut chart when data exists', (tester) async {
      final types = [
        const AttendanceType(
          id: 1,
          name: 'Present',
          abbr: 'ob',
          countAs: AttendanceCountAs.present,
          excuseStatus: AttendanceExcuseStatus.auto,
        ),
      ];
      final attendances = [
        const Attendance(id: 1, eventsId: 1, studentsId: 1, typesId: 1),
      ];

      await tester.pumpWidget(
        _buildTile(attendances: attendances, types: types),
      );
      await tester.pump();

      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.textContaining('%'), findsOneWidget);
    });

    testWidgets('shows present and absent count chips', (tester) async {
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
        _buildTile(attendances: attendances, types: types),
      );
      await tester.pump();

      expect(find.textContaining('Pr.'), findsOneWidget);
      expect(find.textContaining('Ab.'), findsOneWidget);
    });

    testWidgets('header shows Attendance title', (tester) async {
      await tester.pumpWidget(_buildTile());
      await tester.pump();

      expect(find.text('Attendance'), findsOneWidget);
      expect(find.byIcon(Icons.event_available), findsOneWidget);
    });
  });
}
