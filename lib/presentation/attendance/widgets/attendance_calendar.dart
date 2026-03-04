import 'package:bsharp/domain/attendance_utils.dart';
import 'package:bsharp/domain/schedule_utils.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/attendance/providers/attendance_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AttendanceCalendar extends ConsumerWidget {
  const AttendanceCalendar({super.key, this.onDayTap});

  final void Function(DateTime date, AttendanceDay? day)? onDayTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final days = ref.watch(calendarDaysProvider);
    final attendanceDays = ref.watch(attendanceDaysProvider);

    return Column(
      children: [
        _MonthNavigator(
          month: selectedMonth,
          onPrevious: () => _changeMonth(ref, -1),
          onNext: () => _changeMonth(ref, 1),
          onToday: () => _goToToday(ref),
        ),
        const SizedBox(height: 8),
        _WeekdayHeaders(),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, constraints) {
            final cellWidth = constraints.maxWidth / 7;
            final cellHeight = cellWidth.clamp(36.0, 48.0);
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: cellWidth / cellHeight,
              ),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final date = days[index];
                final isCurrentMonth = date.month == selectedMonth.month;
                final dayKey = DateTime(date.year, date.month, date.day);
                final attendanceDay = attendanceDays[dayKey];
                final isToday = isSameDay(date, DateTime.now());

                return _CalendarDay(
                  date: date,
                  isCurrentMonth: isCurrentMonth,
                  isToday: isToday,
                  attendanceDay: attendanceDay,
                  onTap: () => onDayTap?.call(date, attendanceDay),
                );
              },
            );
          },
        ),
        const SizedBox(height: 16),
        const _Legend(),
      ],
    );
  }

  void _changeMonth(WidgetRef ref, int direction) {
    final current = ref.read(selectedMonthProvider);
    ref.read(selectedMonthProvider.notifier).value = DateTime(
      current.year,
      current.month + direction,
    );
  }

  void _goToToday(WidgetRef ref) {
    final now = DateTime.now();
    ref.read(selectedMonthProvider.notifier).value = DateTime(
      now.year,
      now.month,
    );
  }
}

class _MonthNavigator extends StatelessWidget {
  const _MonthNavigator({
    required this.month,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  static List<String> get _monthNames => [
    t.attendance.month.jan,
    t.attendance.month.feb,
    t.attendance.month.mar,
    t.attendance.month.apr,
    t.attendance.month.may,
    t.attendance.month.jun,
    t.attendance.month.jul,
    t.attendance.month.aug,
    t.attendance.month.sep,
    t.attendance.month.oct,
    t.attendance.month.nov,
    t.attendance.month.dec,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final isCurrentMonth = month.year == now.year && month.month == now.month;

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: onPrevious,
          tooltip: t.attendance.previousMonth,
        ),
        Expanded(
          child: Text(
            '${_monthNames[month.month - 1]} ${month.year}',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
        ),
        if (!isCurrentMonth)
          TextButton(onPressed: onToday, child: Text(t.schedule.today)),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: onNext,
          tooltip: t.attendance.nextMonth,
        ),
      ],
    );
  }
}

class _WeekdayHeaders extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dayLabels = [
      t.schedule.dayShort.mon,
      t.schedule.dayShort.tue,
      t.schedule.dayShort.wed,
      t.schedule.dayShort.thu,
      t.schedule.dayShort.fri,
      t.schedule.dayShort.sat,
      t.schedule.dayShort.sun,
    ];
    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Center(
              child: Text(
                dayLabels[i],
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({
    required this.date,
    required this.isCurrentMonth,
    required this.isToday,
    required this.attendanceDay,
    required this.onTap,
  });

  final DateTime date;
  final bool isCurrentMonth;
  final bool isToday;
  final AttendanceDay? attendanceDay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = attendanceDay?.status ?? AttendanceDayStatus.noData;
    final hasData =
        attendanceDay != null && status != AttendanceDayStatus.noData;
    final color = attendanceStatusColor(status);

    return GestureDetector(
      onTap: hasData ? onTap : null,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: hasData && isCurrentMonth
              ? color.withValues(alpha: 0.15)
              : null,
          borderRadius: BorderRadius.circular(8),
          border: isToday
              ? Border.all(color: theme.colorScheme.primary, width: 2)
              : null,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${date.day}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isCurrentMonth
                      ? null
                      : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  fontWeight: isToday ? FontWeight.bold : null,
                ),
              ),
              if (hasData && isCurrentMonth)
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 4,
      children: [
        _LegendItem(
          color: attendanceStatusColor(AttendanceDayStatus.present),
          label: t.attendance.present,
        ),
        _LegendItem(
          color: attendanceStatusColor(AttendanceDayStatus.excused),
          label: t.attendance.excusedLegend,
        ),
        _LegendItem(
          color: attendanceStatusColor(AttendanceDayStatus.unexcused),
          label: t.attendance.unexcusedLegend,
        ),
        _LegendItem(
          color: attendanceStatusColor(AttendanceDayStatus.late),
          label: t.attendance.lateLegend,
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
