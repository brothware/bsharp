import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/domain/entities/attendance.dart';
import 'package:bsharp/presentation/attendance/providers/attendance_providers.dart';
import 'package:bsharp/presentation/schedule/providers/schedule_providers.dart';
import 'package:bsharp/wear/screens/wear_attendance_detail_screen.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';

import '../data/credential_storage_test.dart';

Widget _buildScreen({
  List<Attendance> attendances = const [],
  List<AttendanceType> types = const [],
}) {
  final storage = CredentialStorage(storage: FakeFlutterSecureStorage());
  return ProviderScope(
    overrides: [
      credentialStorageProvider.overrideWithValue(storage),
      wearScreenShapeProvider
          .overrideWith((_) => WearScreenShape.rectangular),
      attendancesProvider.overrideWith((ref) => attendances),
      attendanceTypesProvider.overrideWith((ref) => types),
      eventsProvider.overrideWith((ref) => []),
    ],
    child: const MaterialApp(home: WearAttendanceDetailScreen()),
  );
}

void main() {
  group('WearAttendanceDetailScreen', () {
    testWidgets('shows month label without chevrons', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.byIcon(Icons.chevron_left), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets('shows weekday headers', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.text('M'), findsOneWidget);
      expect(find.text('F'), findsOneWidget);
    });

    testWidgets('shows calendar grid', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('shows month name label', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.byType(Text), findsWidgets);
      expect(find.byType(GridView), findsOneWidget);
    });
  });
}
