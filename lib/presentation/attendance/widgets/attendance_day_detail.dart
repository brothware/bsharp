import 'package:bsharp/domain/attendance_utils.dart';
import 'package:bsharp/domain/schedule_utils.dart';
import 'package:bsharp/domain/translation_utils.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:flutter/material.dart';

class AttendanceDayDetail extends StatelessWidget {
  const AttendanceDayDetail({required this.date, required this.day, super.key});

  final DateTime date;
  final AttendanceDay day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topPadding = MediaQuery.of(context).padding.top;
    final screenHeight = MediaQuery.of(context).size.height;
    final sorted = List<AttendanceEntry>.from(day.entries)
      ..sort((a, b) {
        final aNum = a.event?.number ?? 0;
        final bNum = b.event?.number ?? 0;
        return aNum.compareTo(bNum);
      });

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
              itemCount: sorted.length,
              itemBuilder: (context, index) => _EntryTile(entry: sorted[index]),
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

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry});

  final AttendanceEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = attendanceTypeColor(entry.type.countAs);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              entry.event != null ? '${entry.event!.number}' : '-',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (entry.event != null)
            Text(
              entry.event!.startTime.substring(0, 5),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.subjectName ??
                      '${t.schedule.lessonFallback} ${entry.event?.number ?? ""}',
                  style: theme.textTheme.bodyMedium,
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
  }
}
