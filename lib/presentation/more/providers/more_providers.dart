import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bsharp/domain/entities/portal.dart';
import 'package:bsharp/domain/entities/teacher.dart';
import 'package:bsharp/domain/entities/user_reprimand.dart';
import 'package:bsharp/domain/entities/sync_action.dart';

final homeworksProvider = StateProvider<List<PortalHomework>>((ref) => []);

final testsProvider = StateProvider<List<PortalTest>>((ref) => []);

final reprimandsProvider = StateProvider<List<PortalReprimand>>((ref) => []);

final bulletinsProvider = StateProvider<List<PortalBulletin>>((ref) => []);

final changelogProvider = StateProvider<List<PortalChangelog>>((ref) => []);

enum HomeworkFilter { upcoming, past, all }

final homeworkFilterProvider =
    StateProvider<HomeworkFilter>((ref) => HomeworkFilter.upcoming);

final filteredHomeworksProvider = Provider<List<PortalHomework>>((ref) {
  final all = ref.watch(homeworksProvider);
  final filter = ref.watch(homeworkFilterProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final filtered = switch (filter) {
    HomeworkFilter.upcoming =>
      all.where((h) => _parseDate(h.dueDate).isAfter(today) ||
          _parseDate(h.dueDate).isAtSameMomentAs(today)).toList(),
    HomeworkFilter.past =>
      all.where((h) => _parseDate(h.dueDate).isBefore(today)).toList(),
    HomeworkFilter.all => all,
  };

  return filtered
    ..sort((a, b) => _parseDate(a.dueDate).compareTo(_parseDate(b.dueDate)));
});

final groupedHomeworksProvider =
    Provider<Map<String, List<PortalHomework>>>((ref) {
  final homeworks = ref.watch(filteredHomeworksProvider);
  final grouped = <String, List<PortalHomework>>{};
  for (final hw in homeworks) {
    grouped.putIfAbsent(hw.dueDate, () => []).add(hw);
  }
  return grouped;
});

final upcomingHomeworkProvider = Provider<List<PortalHomework>>((ref) {
  final all = ref.watch(homeworksProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return all
      .where((h) =>
          _parseDate(h.dueDate).isAfter(today) ||
          _parseDate(h.dueDate).isAtSameMomentAs(today))
      .toList()
    ..sort((a, b) => _parseDate(a.dueDate).compareTo(_parseDate(b.dueDate)));
});

final upcomingTestsProvider = Provider<List<PortalTest>>((ref) {
  final all = ref.watch(testsProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return all
      .where((t) => _parseDate(t.date).isAfter(today) ||
          _parseDate(t.date).isAtSameMomentAs(today))
      .toList()
    ..sort((a, b) => _parseDate(a.date).compareTo(_parseDate(b.date)));
});

final remarksProvider = Provider<List<PortalReprimand>>((ref) {
  final all = ref.watch(reprimandsProvider);
  return all.where((r) => r.type == 2).toList()
    ..sort((a, b) => _parseDate(b.date).compareTo(_parseDate(a.date)));
});

final praisesProvider = Provider<List<PortalReprimand>>((ref) {
  final all = ref.watch(reprimandsProvider);
  return all.where((r) => r.type == 1).toList()
    ..sort((a, b) => _parseDate(b.date).compareTo(_parseDate(a.date)));
});

final infoProvider = Provider<List<PortalReprimand>>((ref) {
  final all = ref.watch(reprimandsProvider);
  return all.where((r) => r.type == 0).toList()
    ..sort((a, b) => _parseDate(b.date).compareTo(_parseDate(a.date)));
});

final unreadBulletinsCountProvider = Provider<int>((ref) {
  final bulletins = ref.watch(bulletinsProvider);
  return bulletins.where((b) => !b.isRead).length;
});

final groupedChangelogProvider =
    Provider<Map<String, List<PortalChangelog>>>((ref) {
  final entries = ref.watch(changelogProvider);
  final sorted = List<PortalChangelog>.from(entries)
    ..sort((a, b) => _parseDate(b.date).compareTo(_parseDate(a.date)));
  final grouped = <String, List<PortalChangelog>>{};
  for (final entry in sorted) {
    grouped.putIfAbsent(entry.date, () => []).add(entry);
  }
  return grouped;
});

DateTime _parseDate(String date) {
  try {
    return DateTime.parse(date);
  } catch (_) {
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
