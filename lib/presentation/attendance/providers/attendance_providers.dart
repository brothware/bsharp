import 'package:bsharp/domain/attendance_utils.dart';
import 'package:bsharp/domain/entities/attendance.dart';
import 'package:bsharp/domain/entities/sync_action.dart';
import 'package:bsharp/domain/entities/term.dart';
import 'package:bsharp/presentation/grades/providers/grades_providers.dart';
import 'package:bsharp/presentation/schedule/providers/schedule_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'attendance_providers.g.dart';

@Riverpod(keepAlive: true)
class Attendances extends _$Attendances {
  @override
  List<Attendance> build() => [];
  List<Attendance> get value => state;
  set value(List<Attendance> v) => state = v;
}

@Riverpod(keepAlive: true)
class AttendanceTypes extends _$AttendanceTypes {
  @override
  List<AttendanceType> build() => [];
  List<AttendanceType> get value => state;
  set value(List<AttendanceType> v) => state = v;
}

@Riverpod(keepAlive: true)
class SelectedMonth extends _$SelectedMonth {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  DateTime get value => state;

  set value(DateTime v) => state = v;
}

@Riverpod(keepAlive: true)
Map<DateTime, AttendanceDay> attendanceDays(Ref ref) {
  final attendances = ref.watch(attendancesProvider);
  final types = ref.watch(attendanceTypesProvider);
  final events = ref.watch(eventsProvider);
  return groupByDay(attendances, types, events);
}

@Riverpod(keepAlive: true)
class SelectedStatsTermId extends _$SelectedStatsTermId {
  @override
  int? build() => null;
  int? get value => state;
  set value(int? v) => state = v;
}

@Riverpod(keepAlive: true)
Term? currentStatsTerm(Ref ref) {
  final terms = ref.watch(termsProvider);
  final selectedId = ref.watch(selectedStatsTermIdProvider);

  if (selectedId == 0) return null;

  if (selectedId != null) {
    final match = terms.where((t) => t.id == selectedId);
    if (match.isNotEmpty) return match.first;
  }

  final now = DateTime.now();
  final semesters = terms.where((t) => t.type == TermType.semester);
  final current = semesters.where(
    (t) => !t.startDate.isAfter(now) && !t.endDate.isBefore(now),
  );
  if (current.isNotEmpty) return current.first;
  return null;
}

@Riverpod(keepAlive: true)
AttendanceStats attendanceStats(Ref ref) {
  final attendances = ref.watch(attendancesProvider);
  final types = ref.watch(attendanceTypesProvider);
  final events = ref.watch(eventsProvider);
  final term = ref.watch(currentStatsTermProvider);

  if (term == null) {
    return calculateStats(attendances, types);
  }

  final eventMap = {for (final e in events) e.id: e};
  final filtered = attendances.where((a) {
    final event = eventMap[a.eventsId];
    if (event == null) return false;
    return !event.date.isBefore(term.startDate) &&
        !event.date.isAfter(term.endDate);
  }).toList();

  return calculateStats(filtered, types);
}

@Riverpod(keepAlive: true)
AttendanceDay? attendanceForDay(Ref ref, DateTime date) {
  final days = ref.watch(attendanceDaysProvider);
  final dayKey = DateTime(date.year, date.month, date.day);
  return days[dayKey];
}

final calendarDaysProvider = Provider<List<DateTime>>((ref) {
  final month = ref.watch(selectedMonthProvider);
  return calendarDays(month.year, month.month);
});

class UnexcusedAbsence {
  const UnexcusedAbsence({
    required this.attendance,
    required this.type,
    required this.eventDate,
  });

  final Attendance attendance;
  final AttendanceType type;
  final DateTime eventDate;
}

@Riverpod(keepAlive: true)
List<UnexcusedAbsence> staleUnexcusedAbsences(Ref ref) {
  final attendances = ref.watch(attendancesProvider);
  final types = ref.watch(attendanceTypesProvider);
  final events = ref.watch(eventsProvider);

  final typeMap = {for (final t in types) t.id: t};
  final eventMap = {for (final e in events) e.id: e};
  final cutoff = DateTime.now().subtract(const Duration(days: 7));

  final result = <UnexcusedAbsence>[];
  for (final a in attendances) {
    final type = typeMap[a.typesId];
    if (type == null) continue;
    if (type.countAs != AttendanceCountAs.absent) continue;
    if (type.excuseStatus != AttendanceExcuseStatus.unexcused) continue;

    final event = eventMap[a.eventsId];
    if (event == null) continue;
    if (event.date.isAfter(cutoff)) continue;

    result.add(
      UnexcusedAbsence(attendance: a, type: type, eventDate: event.date),
    );
  }

  result.sort((a, b) => a.eventDate.compareTo(b.eventDate));
  return result;
}
