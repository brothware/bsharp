import 'dart:async';

import 'package:bsharp/app/router.dart';
import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/domain/schedule_utils.dart';
import 'package:bsharp/domain/timeline_item.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/common/widgets/obscurable_fab.dart';
import 'package:bsharp/presentation/schedule/providers/schedule_providers.dart';
import 'package:bsharp/presentation/schedule/widgets/custom_event_card.dart';
import 'package:bsharp/presentation/schedule/widgets/custom_event_detail_sheet.dart';
import 'package:bsharp/presentation/schedule/widgets/lesson_card.dart';
import 'package:bsharp/presentation/schedule/widgets/lesson_detail_sheet.dart';
import 'package:bsharp/presentation/schedule/widgets/linear_day_view.dart';
import 'package:bsharp/presentation/schedule/widgets/week_day_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  List<DateTime> _days = [];
  bool _programmatic = false;
  Offset? _pointerStart;
  int? _tabAtPointerDown;
  bool _changingWeek = false;

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _syncTabController(List<DateTime> days, int selectedIndex) {
    _days = days;
    if (days.length != (_tabController?.length ?? 0)) {
      _tabController?.removeListener(_onTabScroll);
      _tabController?.dispose();
      _tabController = TabController(
        length: days.length,
        initialIndex: selectedIndex,
        animationDuration: Duration.zero,
        vsync: this,
      );
      _tabController!.addListener(_onTabScroll);
    } else if (_tabController!.index != selectedIndex && !_programmatic) {
      _programmatic = true;
      _tabController!.animateTo(selectedIndex);
    }
  }

  void _onTabScroll() {
    final controller = _tabController;
    if (controller == null || _programmatic) {
      if (_programmatic && !_tabController!.indexIsChanging) {
        _programmatic = false;
      }
      return;
    }
    if (!controller.indexIsChanging &&
        controller.index != _indexForCurrentDate()) {
      ref.read(selectedDateProvider.notifier).value = _days[controller.index];
    }
  }

  int _indexForCurrentDate() {
    final selectedDate = ref.read(selectedDateProvider);
    final idx = _days.indexWhere((d) => isSameDay(d, selectedDate));
    return idx >= 0 ? idx : 0;
  }

  void _onTabTapped(int index) {
    ref.read(selectedDateProvider.notifier).value = _days[index];
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final weekStart = ref.watch(selectedWeekStartProvider);
    final hasWeekends = ref.watch(hasWeekendEventsProvider);
    final days = hasWeekends ? weekDaysFull(weekStart) : weekDays(weekStart);
    final viewMode = ref.watch(scheduleViewModeProvider);
    final selectedIndex = days.indexWhere((d) => isSameDay(d, selectedDate));
    final safeIndex = selectedIndex >= 0 ? selectedIndex : 0;

    _syncTabController(days, safeIndex);

    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _WeekNavigator(
              weekStart: weekStart,
              selectedDate: selectedDate,
              viewMode: viewMode,
              onPrevious: () => _changeWeek(-1),
              onNext: () => _changeWeek(1),
              onToday: () => ref.read(selectedDateProvider.notifier).value =
                  DateTime.now(),
              onToggleView: () {
                final next = viewMode == ScheduleViewMode.list
                    ? ScheduleViewMode.linear
                    : ScheduleViewMode.list;
                ref.read(scheduleViewModeProvider.notifier).value = next;
              },
            ),
          ),
          TabBar(
            controller: _tabController,
            onTap: _onTabTapped,
            indicator: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: theme.colorScheme.onPrimaryContainer,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            dividerHeight: 0,
            splashFactory: NoSplash.splashFactory,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            tabs: [for (final day in days) WeekDayTab(date: day)],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${dayLabelFull(selectedDate.weekday)}, '
                '${formatDateFull(selectedDate)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Listener(
              onPointerDown: (e) {
                _pointerStart = e.position;
                _tabAtPointerDown = _tabController?.index;
              },
              onPointerUp: (e) {
                final start = _pointerStart;
                final startTab = _tabAtPointerDown;
                _pointerStart = null;
                _tabAtPointerDown = null;
                if (_changingWeek || start == null || startTab == null) {
                  return;
                }
                final dx = e.position.dx - start.dx;
                final dy = (e.position.dy - start.dy).abs();
                if (dx.abs() < 50 || dy > dx.abs()) return;
                final endTab = _tabController?.index ?? 0;
                if (startTab != endTab) return;
                if (startTab == 0 && dx > 0) {
                  _changeWeek(-1);
                } else if (startTab == days.length - 1 && dx < 0) {
                  _changeWeek(1);
                }
              },
              child: ObscurableFab(
                scrollable: TabBarView(
                  controller: _tabController,
                  children: [
                    for (final day in days)
                      if (viewMode == ScheduleViewMode.list)
                        _DayTimelineList(date: day)
                      else
                        LinearDayView(
                          date: day,
                          onItemTap: (item) => _showItemDetail(context, item),
                        ),
                  ],
                ),
                fab: FloatingActionButton(
                  onPressed: () => context.push(AppRoutes.customEventCreate),
                  tooltip: t.schedule.customEvent.create,
                  child: const Icon(Icons.add),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _changeWeek(int direction) {
    _changingWeek = true;
    final current = ref.read(selectedDateProvider);
    if (direction > 0) {
      final monday = startOfWeek(current);
      ref.read(selectedDateProvider.notifier).value = monday.add(
        const Duration(days: 7),
      );
    } else {
      final friday = endOfWeek(current);
      ref.read(selectedDateProvider.notifier).value = friday.subtract(
        const Duration(days: 7),
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _changingWeek = false;
    });
  }

  static void _showItemDetail(BuildContext context, TimelineItem item) {
    switch (item) {
      case LessonTimelineItem():
        unawaited(
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => LessonDetailSheet(entry: item.entry),
          ),
        );
      case CustomEventTimelineItem():
        unawaited(
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => CustomEventDetailSheet(
              event: item.event,
              date: item.occurrenceDate,
            ),
          ),
        );
    }
  }
}

class _DayTimelineList extends ConsumerWidget {
  const _DayTimelineList({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(timelineItemsForDateProvider(date));

    if (items.isEmpty) {
      return _EmptyDay();
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(syncStatusProvider.notifier).sync(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return switch (item) {
            LessonTimelineItem() => LessonCard(
              entry: item.entry,
              onTap: () => _ScheduleScreenState._showItemDetail(context, item),
            ),
            CustomEventTimelineItem() => CustomEventCard(
              item: item,
              onTap: () => _ScheduleScreenState._showItemDetail(context, item),
            ),
          };
        },
      ),
    );
  }
}

class _WeekNavigator extends StatelessWidget {
  const _WeekNavigator({
    required this.weekStart,
    required this.selectedDate,
    required this.viewMode,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
    required this.onToggleView,
  });

  final DateTime weekStart;
  final DateTime selectedDate;
  final ScheduleViewMode viewMode;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final VoidCallback onToggleView;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weekEnd = endOfWeek(weekStart);
    final isToday = isSameDay(selectedDate, DateTime.now());

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: onPrevious,
          tooltip: t.schedule.previousWeek,
        ),
        Expanded(
          child: Text(
            '${formatDateShort(weekStart)} - ${formatDateShort(weekEnd)}',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
        ),
        if (!isToday)
          TextButton(onPressed: onToday, child: Text(t.schedule.today)),
        IconButton(
          icon: Icon(
            viewMode == ScheduleViewMode.list
                ? Icons.view_timeline_outlined
                : Icons.list,
          ),
          onPressed: onToggleView,
          tooltip: viewMode == ScheduleViewMode.list
              ? t.schedule.viewTimeline
              : t.schedule.viewList,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: onNext,
          tooltip: t.schedule.nextWeek,
        ),
      ],
    );
  }
}

class _EmptyDay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_busy_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(t.schedule.noEvents, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            t.schedule.noEventsSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
