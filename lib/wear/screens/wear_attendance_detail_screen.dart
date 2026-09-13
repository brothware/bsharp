import 'dart:math' as math;

import 'package:bsharp/app/providers/attendance_providers.dart';
import 'package:bsharp/domain/attendance_utils.dart';
import 'package:bsharp/domain/date_utils.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/wear/widgets/wear_period_selector.dart';
import 'package:bsharp/wear/widgets/wear_scaffold.dart';
import 'package:bsharp/wear/widgets/wear_swipe_dismiss.dart';
import 'package:bsharp/wear/widgets/wear_vertical_overscroll_pager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wear_os_scrollbar/wear_os_scrollbar.dart';

class WearAttendanceDetailScreen extends ConsumerStatefulWidget {
  const WearAttendanceDetailScreen({super.key});

  @override
  ConsumerState<WearAttendanceDetailScreen> createState() =>
      _WearAttendanceDetailScreenState();
}

class _WearAttendanceDetailScreenState
    extends ConsumerState<WearAttendanceDetailScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(selectedMonthProvider);
    final calDays = ref.watch(calendarDaysProvider);
    final attDays = ref.watch(attendanceDaysProvider);
    final stats = ref.watch(attendanceStatsProvider);
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    void previousMonth() {
      ref.read(selectedMonthProvider.notifier).value = DateTime(
        month.year,
        month.month - 1,
      );
    }

    void nextMonth() {
      ref.read(selectedMonthProvider.notifier).value = DateTime(
        month.year,
        month.month + 1,
      );
    }

    return WearSwipeDismiss(
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: WearScaffold(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: WearPeriodSelector(
                  label: monthName(month.month),
                  onPrevious: previousMonth,
                  onNext: nextMonth,
                ),
              ),
              const SizedBox(height: 4),
              _WearWeekdayHeaders(theme: theme),
              Expanded(
                child: WearVerticalOverscrollPager(
                  onPrevious: previousMonth,
                  onNext: nextMonth,
                  child: WearOsScrollbar(
                    controller: _scrollController,
                    child: CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        if (stats.totalLessons > 0)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: _WearAttendanceSummary(
                                stats: stats,
                                theme: theme,
                              ),
                            ),
                          ),
                        SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                mainAxisExtent: 30,
                              ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final day = calDays[index];
                              final isCurrentMonth = day.month == month.month;
                              final isToday = day == today;
                              final attDay =
                                  attDays[DateTime(
                                    day.year,
                                    day.month,
                                    day.day,
                                  )];
                              final status =
                                  attDay?.status ?? AttendanceDayStatus.noData;

                              return _WearCalendarDay(
                                day: day,
                                isCurrentMonth: isCurrentMonth,
                                isToday: isToday,
                                status: status,
                                theme: theme,
                              );
                            },
                            childCount: calDays.length,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WearAttendanceSummary extends StatelessWidget {
  const _WearAttendanceSummary({required this.stats, required this.theme});

  final AttendanceStats stats;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CustomPaint(
              key: const Key('attendanceDonut'),
              painter: _DonutPainter(
                percent: stats.presentPercent,
                color: theme.colorScheme.primary,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    attendancePercentLabel(stats.presentPercent),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _WearAttendanceStatChip(
            label: t.attendance.presentAbbr,
            value: '${stats.presentCount}',
            color: theme.colorScheme.primary,
            theme: theme,
          ),
          const SizedBox(width: 6),
          _WearAttendanceStatChip(
            label: t.attendance.absentAbbr,
            value: '${stats.absentCount}',
            color: theme.colorScheme.error,
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _WearAttendanceStatChip extends StatelessWidget {
  const _WearAttendanceStatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.theme,
  });

  final String label;
  final String value;
  final Color color;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 3),
        Text('$label $value', style: theme.textTheme.labelSmall),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.percent,
    required this.color,
    required this.backgroundColor,
  });

  final double percent;
  final Color color;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 5.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final sweepAngle = 2 * math.pi * (percent / 100).clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_DonutPainter oldDelegate) =>
      percent != oldDelegate.percent || color != oldDelegate.color;
}

class _WearWeekdayHeaders extends StatelessWidget {
  const _WearWeekdayHeaders({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final labels = [
      t.schedule.dayLetter.mon,
      t.schedule.dayLetter.tue,
      t.schedule.dayLetter.wed,
      t.schedule.dayLetter.thu,
      t.schedule.dayLetter.fri,
      t.schedule.dayLetter.sat,
      t.schedule.dayLetter.sun,
    ];
    return Container(
      color: theme.colorScheme.surface,
      constraints: const BoxConstraints(minHeight: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: labels
            .map(
              (l) => SizedBox(
                width: 20,
                child: Center(
                  child: Text(
                    l,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _WearCalendarDay extends StatelessWidget {
  const _WearCalendarDay({
    required this.day,
    required this.isCurrentMonth,
    required this.isToday,
    required this.status,
    required this.theme,
  });

  final DateTime day;
  final bool isCurrentMonth;
  final bool isToday;
  final AttendanceDayStatus status;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final dayColor = isCurrentMonth
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurface.withValues(alpha: 0.3);

    return Container(
      decoration: isToday
          ? BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: theme.colorScheme.primary),
            )
          : null,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${day.day}',
              style: theme.textTheme.labelMedium?.copyWith(color: dayColor),
            ),
            if (isCurrentMonth && status != AttendanceDayStatus.noData)
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: attendanceStatusColor(
                    status,
                    brightness: theme.brightness,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
