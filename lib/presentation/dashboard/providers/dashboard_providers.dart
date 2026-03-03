import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bsharp/domain/entities/poczta.dart';
import 'package:bsharp/domain/grade_utils.dart';
import 'package:bsharp/domain/schedule_utils.dart';
import 'package:bsharp/presentation/grades/providers/grades_providers.dart';
import 'package:bsharp/presentation/messages/providers/messages_providers.dart';
import 'package:bsharp/presentation/schedule/providers/schedule_providers.dart';

final todayLessonsProvider = Provider<List<ScheduleEntry>>((ref) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return ref.watch(scheduleEntriesForDateProvider(today));
});

final currentLessonProvider =
    Provider<({ScheduleEntry? current, ScheduleEntry? next, bool allEnded})>((
      ref,
    ) {
      final lessons = ref.watch(todayLessonsProvider);
      if (lessons.isEmpty) {
        return (current: null, next: null, allEnded: false);
      }

      final now = DateTime.now();
      final nowMinutes = now.hour * 60 + now.minute;

      ScheduleEntry? current;
      ScheduleEntry? next;

      for (final entry in lessons) {
        final start = _parseTimeMinutes(entry.event.startTime);
        final end = _parseTimeMinutes(entry.event.endTime);
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
          .map((e) => _parseTimeMinutes(e.event.endTime))
          .whereType<int>()
          .fold<int>(0, (a, b) => a > b ? a : b);

      final allEnded =
          current == null &&
          next == null &&
          lastEnd > 0 &&
          nowMinutes >= lastEnd;

      return (current: current, next: next, allEnded: allEnded);
    });

final recentMarksProvider =
    Provider<List<({ResolvedMark mark, String subjectName})>>((ref) {
      final subjectGrades = ref.watch(subjectGradesProvider);
      final all = <({ResolvedMark mark, String subjectName})>[];

      for (final sg in subjectGrades) {
        for (final rm in sg.resolvedMarks) {
          all.add((mark: rm, subjectName: sg.subjectName));
        }
      }

      all.sort((a, b) {
        final aTime = a.mark.mark.addTime ?? a.mark.mark.getDate;
        final bTime = b.mark.mark.addTime ?? b.mark.mark.getDate;
        return bTime.compareTo(aTime);
      });

      return all.take(5).toList();
    });

final latestUnreadMessagesProvider = Provider<List<PocztaMessage>>((ref) {
  final inbox = ref.watch(inboxProvider);
  final unread = inbox.where((m) => !m.isRead).toList()
    ..sort((a, b) => b.sendTime.compareTo(a.sendTime));
  return unread.take(3).toList();
});

int? _parseTimeMinutes(String time) {
  final parts = time.split(':');
  if (parts.length < 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  return h * 60 + m;
}
