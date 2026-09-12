import 'package:bsharp/domain/entities/portal.dart';
import 'package:bsharp/domain/portal_date_utils.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
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
                parsePortalDate(h.dueDate).isAfter(today) ||
                parsePortalDate(h.dueDate).isAtSameMomentAs(today),
          )
          .toList(),
    HomeworkFilter.past =>
      all.where((h) => parsePortalDate(h.dueDate).isBefore(today)).toList(),
    HomeworkFilter.all => all,
  };

  return filtered..sort(
    (a, b) => parsePortalDate(a.dueDate).compareTo(parsePortalDate(b.dueDate)),
  );
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
            parsePortalDate(h.dueDate).isAfter(today) ||
            parsePortalDate(h.dueDate).isAtSameMomentAs(today),
      )
      .toList()
    ..sort(
      (a, b) =>
          parsePortalDate(a.dueDate).compareTo(parsePortalDate(b.dueDate)),
    );
}

@Riverpod(keepAlive: true)
List<PortalTest> upcomingTests(Ref ref) {
  final all = ref.watch(testsProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return all
      .where(
        (t) =>
            parsePortalDate(t.date).isAfter(today) ||
            parsePortalDate(t.date).isAtSameMomentAs(today),
      )
      .toList()
    ..sort(
      (a, b) => parsePortalDate(a.date).compareTo(parsePortalDate(b.date)),
    );
}

final readNoteIdsProvider = NotifierProvider<ReadNoteIdsNotifier, Set<int>>(
  ReadNoteIdsNotifier.new,
);

class ReadNoteIdsNotifier extends Notifier<Set<int>> {
  static const _key = 'read_note_ids';

  @override
  Set<int> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final stored = prefs.getStringList(_key);
    if (stored == null) return {};
    return stored.map(int.parse).toSet();
  }

  Future<void> markAsRead(int id) async {
    if (state.contains(id)) return;
    final updated = {...state, id};
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setStringList(
      _key,
      updated.map((e) => e.toString()).toList(),
    );
    state = updated;
  }
}

@Riverpod(keepAlive: true)
int unreadRemarksCount(Ref ref) {
  final items = ref.watch(remarksProvider);
  final readIds = ref.watch(readNoteIdsProvider);
  return items.where((r) => !readIds.contains(r.id)).length;
}

@Riverpod(keepAlive: true)
int unreadPraisesCount(Ref ref) {
  final items = ref.watch(praisesProvider);
  final readIds = ref.watch(readNoteIdsProvider);
  return items.where((r) => !readIds.contains(r.id)).length;
}

@Riverpod(keepAlive: true)
int unreadInfoCount(Ref ref) {
  final items = ref.watch(infoProvider);
  final readIds = ref.watch(readNoteIdsProvider);
  return items.where((r) => !readIds.contains(r.id)).length;
}

@Riverpod(keepAlive: true)
List<PortalReprimand> remarks(Ref ref) {
  final all = ref.watch(reprimandsProvider);
  return all.where((r) => r.type == 2).toList()..sort(
    (a, b) => parsePortalDate(b.date).compareTo(parsePortalDate(a.date)),
  );
}

@Riverpod(keepAlive: true)
List<PortalReprimand> praises(Ref ref) {
  final all = ref.watch(reprimandsProvider);
  return all.where((r) => r.type == 1).toList()..sort(
    (a, b) => parsePortalDate(b.date).compareTo(parsePortalDate(a.date)),
  );
}

@Riverpod(keepAlive: true)
List<PortalReprimand> info(Ref ref) {
  final all = ref.watch(reprimandsProvider);
  return all.where((r) => r.type == 0).toList()..sort(
    (a, b) => parsePortalDate(b.date).compareTo(parsePortalDate(a.date)),
  );
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
