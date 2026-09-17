import 'dart:async';

import 'package:bsharp/app/providers/grades_providers.dart';
import 'package:bsharp/app/providers/messages_providers.dart';
import 'package:bsharp/app/providers/schedule_providers.dart';
import 'package:bsharp/domain/entities/poczta.dart';
import 'package:bsharp/domain/entities/resolved_grade.dart';
import 'package:bsharp/domain/schedule_utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dashboard_providers.g.dart';

@Riverpod(keepAlive: true)
List<ScheduleEntry> todayLessons(Ref ref) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return ref.watch(scheduleEntriesForDateProvider(today));
}

@Riverpod(keepAlive: true)
DateTime minuteTick(Ref ref) {
  final now = DateTime.now();
  final nextMinute = DateTime(
    now.year,
    now.month,
    now.day,
    now.hour,
    now.minute + 1,
  );
  final delay = nextMinute.difference(now);
  final timer = Timer(delay, () => ref.invalidateSelf());
  ref.onDispose(timer.cancel);
  return now;
}

@Riverpod(keepAlive: true)
({ScheduleEntry? current, ScheduleEntry? next, bool allEnded}) currentLesson(
  Ref ref,
) {
  final lessons = ref.watch(todayLessonsProvider);
  if (lessons.isEmpty) {
    return (current: null, next: null, allEnded: false);
  }

  final now = ref.watch(minuteTickProvider);
  final nowMinutes = now.hour * 60 + now.minute;

  ScheduleEntry? current;
  ScheduleEntry? next;

  for (final entry in lessons) {
    final start = parseTimeMinutes(entry.startTime);
    final end = parseTimeMinutes(entry.endTime);
    if (start == null || end == null) continue;
    if (entry.isCancelled) continue;

    if (nowMinutes >= start && nowMinutes < end) {
      current = entry;
    } else if (nowMinutes < start && next == null) {
      next = entry;
    }
  }

  final lastEnd = lessons
      .where((e) => !e.isCancelled)
      .map((e) => parseTimeMinutes(e.endTime))
      .whereType<int>()
      .fold<int>(0, (a, b) => a > b ? a : b);

  final allEnded =
      current == null && next == null && lastEnd > 0 && nowMinutes >= lastEnd;

  return (current: current, next: next, allEnded: allEnded);
}

const _nextSchoolDayScanLimit = 60;

@Riverpod(keepAlive: true)
DateTime? nextSchoolDay(Ref ref) {
  final now = DateTime.now();
  var day = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));

  for (var i = 0; i < _nextSchoolDayScanLimit; i++) {
    final entries = ref.watch(scheduleEntriesForDateProvider(day));
    if (entries.any((e) => !e.isCancelled)) {
      return day;
    }
    day = day.add(const Duration(days: 1));
  }

  return null;
}

@Riverpod(keepAlive: true)
List<({ResolvedGrade grade, String subjectName})> recentMarks(Ref ref) {
  final grades = ref.watch(subjectGradesProvider);
  final all = <({ResolvedGrade grade, String subjectName})>[];

  for (final sg in grades) {
    for (final g in sg.grades) {
      all.add((grade: g, subjectName: sg.subjectName));
    }
  }

  all.sort((a, b) => b.grade.date.compareTo(a.grade.date));

  return all.take(5).toList();
}

@Riverpod(keepAlive: true)
List<PocztaMessage> latestUnreadMessages(Ref ref) {
  final inbox = ref.watch(inboxProvider);
  final unread = inbox.where((m) => !m.isRead).toList()
    ..sort((a, b) => b.sendTime.compareTo(a.sendTime));
  return unread.take(3).toList();
}
