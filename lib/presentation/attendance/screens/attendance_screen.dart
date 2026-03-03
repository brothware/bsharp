import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/domain/attendance_utils.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/attendance/providers/attendance_providers.dart';
import 'package:bsharp/presentation/attendance/widgets/attendance_calendar.dart';
import 'package:bsharp/presentation/attendance/widgets/attendance_day_detail.dart';
import 'package:bsharp/presentation/attendance/widgets/attendance_stats_view.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: RefreshIndicator(
        onRefresh: () => ref.read(syncStatusProvider.notifier).sync(),
        child: Column(
          children: [
            TabBar(
              tabs: [
                Tab(text: t.attendance.calendar),
                Tab(text: t.attendance.statistics),
              ],
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant,
              indicatorSize: TabBarIndicatorSize.label,
            ),
            Expanded(
              child: TabBarView(
                children: [_CalendarTab(), const AttendanceStatsView()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendances = ref.watch(attendancesProvider);

    if (attendances.isEmpty) {
      return _EmptyState();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AttendanceCalendar(
          onDayTap: (date, day) {
            if (day != null) {
              _showDayDetail(context, date, day);
            }
          },
        ),
      ],
    );
  }

  void _showDayDetail(BuildContext context, DateTime date, AttendanceDay day) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AttendanceDayDetail(date: date, day: day),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 80),
        Icon(
          Icons.event_available_outlined,
          size: 64,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 16),
        Text(
          t.attendance.noData,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          t.attendance.noDataSubtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
