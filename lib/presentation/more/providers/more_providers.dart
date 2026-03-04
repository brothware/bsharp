import 'package:bsharp/domain/entities/portal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'more_providers.g.dart';

@Riverpod(keepAlive: true)
class Homeworks extends _$Homeworks {
  @override
  List<PortalHomework> build() => [];
  List<PortalHomework> get value => state;
  set value(List<PortalHomework> v) => state = v;
}

@Riverpod(keepAlive: true)
class Tests extends _$Tests {
  @override
  List<PortalTest> build() => [];
  List<PortalTest> get value => state;
  set value(List<PortalTest> v) => state = v;
}

@Riverpod(keepAlive: true)
class Reprimands extends _$Reprimands {
  @override
  List<PortalReprimand> build() => [];
  List<PortalReprimand> get value => state;
  set value(List<PortalReprimand> v) => state = v;
}

@Riverpod(keepAlive: true)
class Bulletins extends _$Bulletins {
  @override
  List<PortalBulletin> build() => [];
  List<PortalBulletin> get value => state;
  set value(List<PortalBulletin> v) => state = v;
}

@Riverpod(keepAlive: true)
class GradeChangelog extends _$GradeChangelog {
  @override
  List<PortalChangelog> build() => [];
  List<PortalChangelog> get value => state;
  set value(List<PortalChangelog> v) => state = v;
}

@Riverpod(keepAlive: true)
class AttendanceChangelog extends _$AttendanceChangelog {
  @override
  List<PortalChangelog> build() => [];
  List<PortalChangelog> get value => state;
  set value(List<PortalChangelog> v) => state = v;
}

enum HomeworkFilter { upcoming, past, all }

class HomeworkFilterNotifier extends Notifier<HomeworkFilter> {
  @override
  HomeworkFilter build() => HomeworkFilter.upcoming;
  HomeworkFilter get value => state;
  set value(HomeworkFilter v) => state = v;
}

final homeworkFilterProvider =
    NotifierProvider<HomeworkFilterNotifier, HomeworkFilter>(
      HomeworkFilterNotifier.new,
    );

@Riverpod(keepAlive: true)
List<PortalHomework> filteredHomeworks(Ref ref) {
  final all = ref.watch(homeworksProvider);
  final filter = ref.watch(homeworkFilterProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final filtered = switch (filter) {
    HomeworkFilter.upcoming =>
      all
          .where(
            (h) =>
                _parseDate(h.dueDate).isAfter(today) ||
                _parseDate(h.dueDate).isAtSameMomentAs(today),
          )
          .toList(),
    HomeworkFilter.past =>
      all.where((h) => _parseDate(h.dueDate).isBefore(today)).toList(),
    HomeworkFilter.all => all,
  };

  return filtered
    ..sort((a, b) => _parseDate(a.dueDate).compareTo(_parseDate(b.dueDate)));
}

@Riverpod(keepAlive: true)
Map<String, List<PortalHomework>> groupedHomeworks(Ref ref) {
  final homeworks = ref.watch(filteredHomeworksProvider);
  final grouped = <String, List<PortalHomework>>{};
  for (final hw in homeworks) {
    grouped.putIfAbsent(hw.dueDate, () => []).add(hw);
  }
  return grouped;
}

@Riverpod(keepAlive: true)
List<PortalHomework> upcomingHomework(Ref ref) {
  final all = ref.watch(homeworksProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return all
      .where(
        (h) =>
            _parseDate(h.dueDate).isAfter(today) ||
            _parseDate(h.dueDate).isAtSameMomentAs(today),
      )
      .toList()
    ..sort((a, b) => _parseDate(a.dueDate).compareTo(_parseDate(b.dueDate)));
}

@Riverpod(keepAlive: true)
List<PortalTest> upcomingTests(Ref ref) {
  final all = ref.watch(testsProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return all
      .where(
        (t) =>
            _parseDate(t.date).isAfter(today) ||
            _parseDate(t.date).isAtSameMomentAs(today),
      )
      .toList()
    ..sort((a, b) => _parseDate(a.date).compareTo(_parseDate(b.date)));
}

@Riverpod(keepAlive: true)
List<PortalReprimand> remarks(Ref ref) {
  final all = ref.watch(reprimandsProvider);
  return all.where((r) => r.type == 2).toList()
    ..sort((a, b) => _parseDate(b.date).compareTo(_parseDate(a.date)));
}

@Riverpod(keepAlive: true)
List<PortalReprimand> praises(Ref ref) {
  final all = ref.watch(reprimandsProvider);
  return all.where((r) => r.type == 1).toList()
    ..sort((a, b) => _parseDate(b.date).compareTo(_parseDate(a.date)));
}

@Riverpod(keepAlive: true)
List<PortalReprimand> info(Ref ref) {
  final all = ref.watch(reprimandsProvider);
  return all.where((r) => r.type == 0).toList()
    ..sort((a, b) => _parseDate(b.date).compareTo(_parseDate(a.date)));
}

@Riverpod(keepAlive: true)
int unreadBulletinsCount(Ref ref) {
  final bulletins = ref.watch(bulletinsProvider);
  return bulletins.where((b) => !b.isRead).length;
}

@Riverpod(keepAlive: true)
Map<String, List<PortalChangelog>> groupedGradeChangelog(Ref ref) {
  return _groupChangelogByDate(ref.watch(gradeChangelogProvider));
}

@Riverpod(keepAlive: true)
Map<String, List<PortalChangelog>> groupedAttendanceChangelog(Ref ref) {
  return _groupChangelogByDate(ref.watch(attendanceChangelogProvider));
}

Map<String, List<PortalChangelog>> _groupChangelogByDate(
  List<PortalChangelog> entries,
) {
  final sorted = List<PortalChangelog>.from(entries)
    ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  final grouped = <String, List<PortalChangelog>>{};
  for (final entry in sorted) {
    final date = entry.dateTime.length >= 10
        ? entry.dateTime.substring(0, 10)
        : entry.dateTime;
    grouped.putIfAbsent(date, () => []).add(entry);
  }
  return grouped;
}

DateTime _parseDate(String date) {
  try {
    return DateTime.parse(date);
  } on FormatException {
    final parts = date.split('.');
    if (parts.length == 3) {
      return DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    }
    return DateTime(2000);
  }
}
