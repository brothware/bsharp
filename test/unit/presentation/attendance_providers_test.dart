import 'package:bsharp/domain/entities/attendance.dart';
import 'package:bsharp/domain/entities/event.dart';
import 'package:bsharp/domain/entities/sync_action.dart';
import 'package:bsharp/domain/entities/term.dart';
import 'package:bsharp/presentation/attendance/providers/attendance_providers.dart';
import 'package:bsharp/presentation/grades/providers/grades_providers.dart';
import 'package:bsharp/presentation/schedule/providers/schedule_providers.dart';
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

  const absentType = AttendanceType(
    id: 2,
    name: 'Absent',
    abbr: 'NB',
    countAs: AttendanceCountAs.absent,
    excuseStatus: AttendanceExcuseStatus.unexcused,
  );

  Attendance attendance({int id = 1, int eventsId = 1, int typesId = 1}) {
    return Attendance(
      id: id,
      eventsId: eventsId,
      studentsId: 1,
      typesId: typesId,
    );
  }

  Event event({int id = 1, DateTime? date}) {
    return Event(
      id: id,
      date: date ?? DateTime(2026, 2, 27),
      number: 1,
      startTime: '08:00:00',
      endTime: '08:45:00',
      eventTypesId: 1,
      status: 1,
      substitution: 0,
      type: 0,
      attr: 0,
      locked: 0,
    );
  }

  group('attendanceDaysProvider', () {
    test('groups by event date', () {
      final container = ProviderContainer(
        overrides: [
          attendancesProvider.overrideWithBuild(
            (ref, _) => [
              attendance(),
              attendance(id: 2, eventsId: 2, typesId: 2),
            ],
          ),
          attendanceTypesProvider.overrideWithBuild(
            (ref, _) => [presentType, absentType],
          ),
          eventsProvider.overrideWithBuild(
            (ref, _) => [
              event(date: DateTime(2026, 2, 27)),
              event(id: 2, date: DateTime(2026, 2, 28)),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      final days = container.read(attendanceDaysProvider);
      expect(days.length, 2);
      expect(days[DateTime(2026, 2, 27)], isNotNull);
      expect(days[DateTime(2026, 2, 28)], isNotNull);
    });

    test('returns empty when no attendances', () {
      final container = ProviderContainer(
        overrides: [
          attendancesProvider.overrideWithBuild((ref, _) => []),
          attendanceTypesProvider.overrideWithBuild((ref, _) => []),
          eventsProvider.overrideWithBuild((ref, _) => []),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(attendanceDaysProvider), isEmpty);
    });
  });

  group('attendanceStatsProvider', () {
    test('calculates stats from all attendances when no term selected', () {
      final container = ProviderContainer(
        overrides: [
          attendancesProvider.overrideWithBuild(
            (ref, _) => [
              attendance(),
              attendance(id: 2, eventsId: 2),
              attendance(id: 3, eventsId: 3, typesId: 2),
            ],
          ),
          attendanceTypesProvider.overrideWithBuild(
            (ref, _) => [presentType, absentType],
          ),
          eventsProvider.overrideWithBuild(
            (ref, _) => [
              event(date: DateTime(2025, 10)),
              event(id: 2, date: DateTime(2026, 3)),
              event(id: 3, date: DateTime(2026, 3, 15)),
            ],
          ),
          selectedStatsTermIdProvider.overrideWithBuild((ref, _) => 0),
        ],
      );
      addTearDown(container.dispose);

      final stats = container.read(attendanceStatsProvider);
      expect(stats.totalLessons, 3);
      expect(stats.presentCount, 2);
      expect(stats.absentCount, 1);
    });

    test('filters stats by selected semester', () {
      final container = ProviderContainer(
        overrides: [
          attendancesProvider.overrideWithBuild(
            (ref, _) => [
              attendance(),
              attendance(id: 2, eventsId: 2),
              attendance(id: 3, eventsId: 3, typesId: 2),
            ],
          ),
          attendanceTypesProvider.overrideWithBuild(
            (ref, _) => [presentType, absentType],
          ),
          eventsProvider.overrideWithBuild(
            (ref, _) => [
              event(date: DateTime(2025, 10)),
              event(id: 2, date: DateTime(2026, 3)),
              event(id: 3, date: DateTime(2026, 3, 15)),
            ],
          ),
          termsProvider.overrideWithBuild(
            (ref, _) => [
              Term(
                id: 4,
                parentId: 1,
                name: 'Semestr 1',
                type: TermType.semester,
                startDate: DateTime(2025, 9),
                endDate: DateTime(2026, 2, 15),
              ),
              Term(
                id: 7,
                parentId: 1,
                name: 'Semestr 2',
                type: TermType.semester,
                startDate: DateTime(2026, 2, 16),
                endDate: DateTime(2026, 6, 26),
              ),
            ],
          ),
          selectedStatsTermIdProvider.overrideWithBuild((ref, _) => 7),
        ],
      );
      addTearDown(container.dispose);

      final stats = container.read(attendanceStatsProvider);
      expect(stats.totalLessons, 2);
      expect(stats.presentCount, 1);
      expect(stats.absentCount, 1);
    });
  });

  group('attendanceForDayProvider', () {
    test('returns day data for matching date', () {
      final container = ProviderContainer(
        overrides: [
          attendancesProvider.overrideWithBuild((ref, _) => [attendance()]),
          attendanceTypesProvider.overrideWithBuild((ref, _) => [presentType]),
          eventsProvider.overrideWithBuild(
            (ref, _) => [event(date: DateTime(2026, 2, 27))],
          ),
        ],
      );
      addTearDown(container.dispose);

      final day = container.read(
        attendanceForDayProvider(DateTime(2026, 2, 27)),
      );
      expect(day, isNotNull);
      expect(day!.entries.length, 1);
    });

    test('returns null for date with no data', () {
      final container = ProviderContainer(
        overrides: [
          attendancesProvider.overrideWithBuild((ref, _) => []),
          attendanceTypesProvider.overrideWithBuild((ref, _) => []),
          eventsProvider.overrideWithBuild((ref, _) => []),
        ],
      );
      addTearDown(container.dispose);

      final day = container.read(
        attendanceForDayProvider(DateTime(2026, 2, 27)),
      );
      expect(day, isNull);
    });
  });

  group('calendarDaysProvider', () {
    test('returns days for selected month', () {
      final container = ProviderContainer(
        overrides: [
          selectedMonthProvider.overrideWithBuild(
            (ref, _) => DateTime(2026, 2),
          ),
        ],
      );
      addTearDown(container.dispose);

      final days = container.read(calendarDaysProvider);
      expect(days.length % 7, 0);
      final febDays = days.where((d) => d.month == 2 && d.year == 2026);
      expect(febDays.length, 28);
    });
  });
}
