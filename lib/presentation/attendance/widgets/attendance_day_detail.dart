import 'package:bsharp/domain/attendance_utils.dart';
import 'package:bsharp/domain/entities/resolved_event.dart';
import 'package:bsharp/domain/entities/sync_action.dart';
import 'package:bsharp/domain/schedule_utils.dart';
import 'package:bsharp/domain/translation_utils.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/attendance/providers/attendance_providers.dart';
import 'package:bsharp/presentation/schedule/providers/schedule_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AttendanceDayDetail extends ConsumerWidget {
  const AttendanceDayDetail({required this.date, required this.day, super.key});

  final DateTime date;
  final AttendanceDay day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final topPadding = MediaQuery.of(context).padding.top;
    final screenHeight = MediaQuery.of(context).size.height;
    final ignoredIds =
        ref.watch(ignoredAttendanceIdsProvider).value ?? const <int>{};

    final dayKey = DateTime(date.year, date.month, date.day);
    final resolvedEvents = ref.watch(resolvedEventsProvider);
    final coveredEventIds = {
      for (final e in day.entries)
        if (e.resolvedEvent != null) e.resolvedEvent!.id,
    };
    final unlabeledEvents = resolvedEvents.where((e) {
      final eDay = DateTime(e.date.year, e.date.month, e.date.day);
      if (eDay != dayKey) return false;
      if (e.isCancelled && !e.isReplaced) return false;
      return !coveredEventIds.contains(e.id);
    }).toList();

    final items = <_DayItem>[
      for (final entry in day.entries) _DayItem.entry(entry),
      for (final event in unlabeledEvents) _DayItem.unlabeled(event),
    ]..sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));

    final title = '${dayLabelFull(date.weekday)}, ${formatDateFull(date)}';

    return Container(
      height: screenHeight - topPadding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 56,
            child: Row(
              children: [
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: attendanceStatusColor(day.status),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _statusLabel(day.status),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: attendanceStatusColor(day.status),
                  ),
                ),
                const Spacer(),
                Text(
                  t.attendance.presenceCount(
                    present: day.presentCount,
                    total: day.entries.length,
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return switch (item) {
                  _EntryItem(:final entry) => _EntryTile(
                    entry: entry,
                    isIgnored: ignoredIds.contains(entry.attendance.id),
                  ),
                  _UnlabeledItem(:final event) => _UnlabeledEventTile(
                    event: event,
                  ),
                };
              },
            ),
          ),
        ],
      ),
    );
  }

  static String _statusLabel(AttendanceDayStatus status) {
    return switch (status) {
      AttendanceDayStatus.present => t.attendance.fullPresence,
      AttendanceDayStatus.excused => t.attendance.excusedLabel,
      AttendanceDayStatus.unexcused => t.attendance.unexcusedLabel,
      AttendanceDayStatus.late => t.attendance.lateLabel,
      AttendanceDayStatus.mixed => t.attendance.partialPresence,
      AttendanceDayStatus.noData => t.attendance.noDataLabel,
    };
  }
}

sealed class _DayItem {
  const _DayItem();

  factory _DayItem.entry(AttendanceEntry e) = _EntryItem;
  factory _DayItem.unlabeled(ResolvedEvent e) = _UnlabeledItem;

  int get lessonNumber;
}

class _EntryItem extends _DayItem {
  const _EntryItem(this.entry);
  final AttendanceEntry entry;

  @override
  int get lessonNumber => entry.resolvedEvent?.number ?? 0;
}

class _UnlabeledItem extends _DayItem {
  const _UnlabeledItem(this.event);
  final ResolvedEvent event;

  @override
  int get lessonNumber => event.number;
}

class _UnlabeledEventTile extends StatelessWidget {
  const _UnlabeledEventTile({required this.event});

  final ResolvedEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;

    final subjectName = event.subjectName != null
        ? translateSubjectName(event.subjectName!)
        : '${t.schedule.lessonFallback} ${event.number}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '${event.number}',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(color: color),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            event.startTime.substring(0, 5),
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subjectName, style: theme.textTheme.bodyMedium),
                Text(
                  t.attendance.noDataLabel,
                  style: theme.textTheme.bodySmall?.copyWith(color: color),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '—',
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryTile extends ConsumerWidget {
  const _EntryTile({required this.entry, required this.isIgnored});

  final AttendanceEntry entry;
  final bool isIgnored;

  bool get _isUnexcusedAbsence =>
      entry.type.countAs == AttendanceCountAs.absent &&
      entry.type.excuseStatus == AttendanceExcuseStatus.unexcused;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = attendanceTypeColor(
      entry.type.countAs,
      entry.type.excuseStatus,
    );

    final tile = Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              entry.displayLessonNumber ??
                  (entry.resolvedEvent != null
                      ? '${entry.resolvedEvent!.number}'
                      : '-'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (entry.resolvedEvent != null)
            Text(
              entry.resolvedEvent!.startTime.substring(0, 5),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.subjectName ??
                            '${t.schedule.lessonFallback} ${entry.displayLessonNumber ?? entry.resolvedEvent?.number ?? ""}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    if (isIgnored) ...[
                      const SizedBox(width: 6),
                      Tooltip(
                        message: t.attendance.ignoredLabel,
                        child: Icon(
                          Icons.visibility_off_outlined,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  translateAttendanceName(entry.type.name),
                  style: theme.textTheme.bodySmall?.copyWith(color: color),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              translateAttendanceAbbr(entry.type.abbr),
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (!_isUnexcusedAbsence) return tile;

    return InkWell(onTap: () => _confirmToggle(context, ref), child: tile);
  }

  Future<void> _confirmToggle(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isIgnored
              ? t.attendance.unignoreAbsenceConfirmTitle
              : t.attendance.ignoreAbsenceConfirmTitle,
        ),
        content: Text(
          isIgnored
              ? t.attendance.unignoreAbsenceConfirmBody
              : t.attendance.ignoreAbsenceConfirmBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.attendance.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              isIgnored ? t.attendance.unignore : t.attendance.ignore,
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final dao = ref.read(ignoredAttendanceDaoProvider);
    if (dao == null) return;
    if (isIgnored) {
      await dao.markUnignored(entry.attendance.id);
    } else {
      await dao.markIgnored(entry.attendance.id);
    }
  }
}
