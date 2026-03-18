import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/domain/entities/attendance.dart';
import 'package:bsharp/presentation/attendance/providers/attendance_providers.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:bsharp/presentation/schedule/providers/schedule_providers.dart';
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
}) {
  final storage = CredentialStorage(store: FakeKeyValueStore());
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      credentialStorageProvider.overrideWithValue(storage),
      wearScreenShapeProvider.overrideWith((_) => WearScreenShape.rectangular),
      attendancesProvider.overrideWithBuild((ref, _) => attendances),
      attendanceTypesProvider.overrideWithBuild((ref, _) => types),
      resolvedEventsProvider.overrideWithBuild((ref, _) => []),
    ],
    child: const MaterialApp(home: WearAttendanceDetailScreen()),
  );
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('WearAttendanceDetailScreen', () {
    testWidgets('shows month label without chevrons', (tester) async {
      await tester.pumpWidget(_buildScreen(prefs: prefs));
      await tester.pump();

      expect(find.byIcon(Icons.chevron_left), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
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

      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('shows month name label', (tester) async {
      await tester.pumpWidget(_buildScreen(prefs: prefs));
      await tester.pump();

      expect(find.byType(Text), findsWidgets);
      expect(find.byType(GridView), findsOneWidget);
    });
  });
}
