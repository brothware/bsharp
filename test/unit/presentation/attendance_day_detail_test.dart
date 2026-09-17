import 'package:bsharp/app/providers/schedule_providers.dart';
import 'package:bsharp/domain/attendance_utils.dart';
import 'package:bsharp/domain/entities/attendance.dart';
import 'package:bsharp/domain/entities/resolved_event.dart';
import 'package:bsharp/domain/entities/sync_action.dart';
import 'package:bsharp/presentation/attendance/widgets/attendance_day_detail.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  const presentType = AttendanceType(
    id: 1,
    name: 'Present',
    abbr: 'OB',
    countAs: AttendanceCountAs.present,
    excuseStatus: AttendanceExcuseStatus.auto,
  );

  final day = DateTime(2026, 9, 17);

  ResolvedEvent event({
    required int id,
    required int number,
    required String startTime,
    required String endTime,
    String? subjectName,
    String? eventName,
  }) {
    return ResolvedEvent(
      id: id,
      date: day,
      number: number,
      startTime: startTime,
      endTime: endTime,
      subjectName: subjectName,
      eventName: eventName,
    );
  }

  testWidgets('orders rows chronologically with the rehearsal in its slot', (
    tester,
  ) async {
    final nature = event(
      id: 1,
      number: 1,
      startTime: '08:00:00',
      endTime: '08:45:00',
      subjectName: 'przyroda',
    );
    final maths = event(
      id: 2,
      number: 4,
      startTime: '10:40:00',
      endTime: '11:25:00',
      subjectName: 'matematyka',
    );
    final rehearsal = event(
      id: 3,
      number: 0,
      startTime: '10:40:00',
      endTime: '13:15:00',
      eventName: 'Próba',
    );

    final attendanceDay = AttendanceDay(
      date: day,
      entries: [
        AttendanceEntry(
          attendance: const Attendance(
            id: 100,
            eventsId: 1,
            studentsId: 1,
            typesId: 1,
          ),
          type: presentType,
          resolvedEvent: nature,
          subjectName: 'przyroda',
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          resolvedEventsProvider.overrideWithBuild(
            (ref, _) => [nature, maths, rehearsal],
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: AttendanceDayDetail(date: day, day: attendanceDay),
          ),
        ),
      ),
    );
    await tester.pump();

    final rows = tester
        .widgetList<Text>(find.byType(Text))
        .map((w) => w.data)
        .whereType<String>()
        .toList();

    expect(
      rows.indexOf('przyroda'),
      lessThan(rows.indexOf('Próba')),
      reason: 'the 08:00 lesson comes before the 10:40 rehearsal',
    );
    expect(
      rows.indexOf('Próba'),
      lessThan(rows.indexOf('matematyka')),
      reason: 'the rehearsal leads the lessons it overlaps',
    );
    expect(
      rows.contains('-'),
      isTrue,
      reason: 'no lesson number is shown as 0',
    );
    expect(rows.contains('0'), isFalse);
  });
}
