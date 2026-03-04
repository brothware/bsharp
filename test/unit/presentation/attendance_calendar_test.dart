import 'package:bsharp/domain/entities/attendance.dart';
import 'package:bsharp/domain/entities/event.dart';
import 'package:bsharp/domain/entities/sync_action.dart';
import 'package:bsharp/presentation/attendance/providers/attendance_providers.dart';
import 'package:bsharp/presentation/attendance/screens/attendance_screen.dart';
import 'package:bsharp/presentation/attendance/widgets/attendance_stats_view.dart';
import 'package:bsharp/presentation/schedule/providers/schedule_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const presentType = AttendanceType(
    id: 1,
    name: 'Present',
    abbr: 'OB',
    countAs: AttendanceCountAs.present,
    excuseStatus: AttendanceExcuseStatus.auto,
  );

  Widget wrap({
    List<Attendance> attendances = const [],
    List<AttendanceType> types = const [],
    List<Event> events = const [],
  }) {
    return ProviderScope(
      overrides: [
        attendancesProvider.overrideWithBuild((ref, _) => attendances),
        attendanceTypesProvider.overrideWithBuild((ref, _) => types),
        eventsProvider.overrideWithBuild((ref, _) => events),
        selectedMonthProvider.overrideWithBuild((ref, _) => DateTime(2026, 2)),
      ],
      child: const MaterialApp(home: Scaffold(body: AttendanceScreen())),
    );
  }

  testWidgets('shows tabs for Kalendarz and Statystyki', (tester) async {
    await tester.pumpWidget(wrap());

    expect(find.text('Calendar'), findsOneWidget);
    expect(find.text('Statistics'), findsOneWidget);
  });

  testWidgets('shows empty state when no attendances', (tester) async {
    await tester.pumpWidget(wrap());

    expect(find.text('No attendance data'), findsOneWidget);
  });

  testWidgets('shows calendar when attendances present', (tester) async {
    await tester.pumpWidget(
      wrap(
        attendances: [
          const Attendance(id: 1, eventsId: 1, studentsId: 1, typesId: 1),
        ],
        types: [presentType],
        events: [
          Event(
            id: 1,
            date: DateTime(2026, 2, 27),
            number: 1,
            startTime: '08:00:00',
            endTime: '08:45:00',
            eventTypesId: 1,
            status: 1,
            substitution: 0,
            type: 0,
            attr: 0,
            locked: 0,
          ),
        ],
      ),
    );

    expect(find.text('Present'), findsOneWidget);
    expect(find.text('Excused'), findsOneWidget);
    expect(find.text('Unexcused'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);
  });

  testWidgets('shows stats tab content', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.tap(find.text('Statistics'));
    await tester.pumpAndSettle();

    expect(find.text('No data'), findsOneWidget);
  });

  testWidgets('shows month name in calendar', (tester) async {
    await tester.pumpWidget(
      wrap(
        attendances: [
          const Attendance(id: 1, eventsId: 1, studentsId: 1, typesId: 1),
        ],
        types: [presentType],
        events: [
          Event(
            id: 1,
            date: DateTime(2026, 2, 15),
            number: 1,
            startTime: '08:00:00',
            endTime: '08:45:00',
            eventTypesId: 1,
            status: 1,
            substitution: 0,
            type: 0,
            attr: 0,
            locked: 0,
          ),
        ],
      ),
    );

    expect(find.text('February 2026'), findsOneWidget);
  });

  testWidgets('shows weekday headers', (tester) async {
    await tester.pumpWidget(
      wrap(
        attendances: [
          const Attendance(id: 1, eventsId: 1, studentsId: 1, typesId: 1),
        ],
        types: [presentType],
        events: [
          Event(
            id: 1,
            date: DateTime(2026, 2, 15),
            number: 1,
            startTime: '08:00:00',
            endTime: '08:45:00',
            eventTypesId: 1,
            status: 1,
            substitution: 0,
            type: 0,
            attr: 0,
            locked: 0,
          ),
        ],
      ),
    );

    expect(find.text('Mon'), findsOneWidget);
    expect(find.text('Fri'), findsOneWidget);
  });

  testWidgets('stats view shows stats when data present', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          attendancesProvider.overrideWithBuild(
            (ref, _) => [
              const Attendance(id: 1, eventsId: 1, studentsId: 1, typesId: 1),
              const Attendance(id: 2, eventsId: 2, studentsId: 1, typesId: 1),
            ],
          ),
          attendanceTypesProvider.overrideWithBuild((ref, _) => [presentType]),
        ],
        child: const MaterialApp(home: Scaffold(body: AttendanceStatsView())),
      ),
    );

    expect(find.text('Overall attendance'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('2'), findsWidgets);
  });
}
