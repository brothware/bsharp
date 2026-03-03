import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bsharp/domain/attendance_utils.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/attendance/providers/attendance_providers.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:bsharp/wear/widgets/wear_screen_layout.dart';
import 'package:bsharp/wear/widgets/wear_swipe_dismiss.dart';
import 'package:bsharp/wear/widgets/wear_vertical_overscroll_pager.dart';

class WearAttendanceDetailScreen extends ConsumerWidget {
  const WearAttendanceDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shape = ref.watch(wearScreenShapeProvider).requireValue;
    final month = ref.watch(selectedMonthProvider);
    final calDays = ref.watch(calendarDaysProvider);
    final attDays = ref.watch(attendanceDaysProvider);
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return WearSwipeDismiss(
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: WearScreenLayout(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _monthName(month.month),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              _WearWeekdayHeaders(theme: theme),
              const SizedBox(height: 2),
              Expanded(
                child: WearVerticalOverscrollPager(
                  onPrevious: () {
                    ref.read(selectedMonthProvider.notifier).state = DateTime(
                      month.year,
                      month.month - 1,
                    );
                  },
                  onNext: () {
                    ref.read(selectedMonthProvider.notifier).state = DateTime(
                      month.year,
                      month.month + 1,
                    );
                  },
                  child: GridView.builder(
                    padding: EdgeInsets.only(
                      bottom: wearListBottomInset(shape),
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                        ),
                    itemCount: calDays.length,
                    itemBuilder: (context, index) {
                      final day = calDays[index];
                      final isCurrentMonth = day.month == month.month;
                      final isToday = day == today;
                      final attDay =
                          attDays[DateTime(day.year, day.month, day.day)];
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

String _monthName(int month) {
  return switch (month) {
    1 => t.attendance.month.jan,
    2 => t.attendance.month.feb,
    3 => t.attendance.month.mar,
    4 => t.attendance.month.apr,
    5 => t.attendance.month.may,
    6 => t.attendance.month.jun,
    7 => t.attendance.month.jul,
    8 => t.attendance.month.aug,
    9 => t.attendance.month.sep,
    10 => t.attendance.month.oct,
    11 => t.attendance.month.nov,
    12 => t.attendance.month.dec,
    _ => '',
  };
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: labels
          .map(
            (l) => SizedBox(
              width: 20,
              child: Center(
                child: Text(
                  l,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 8,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          )
          .toList(),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 8,
              color: dayColor,
            ),
          ),
          if (isCurrentMonth && status != AttendanceDayStatus.noData)
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: attendanceStatusColor(status),
              ),
            ),
        ],
      ),
    );
  }
}
