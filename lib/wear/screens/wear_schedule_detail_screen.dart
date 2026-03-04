import 'package:bsharp/domain/schedule_utils.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/schedule/providers/schedule_providers.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:bsharp/wear/widgets/wear_crown_scroll.dart';
import 'package:bsharp/wear/widgets/wear_screen_layout.dart';
import 'package:bsharp/wear/widgets/wear_swipe_dismiss.dart';
import 'package:bsharp/wear/widgets/wear_vertical_overscroll_pager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WearScheduleDetailScreen extends ConsumerStatefulWidget {
  const WearScheduleDetailScreen({super.key});

  @override
  ConsumerState<WearScheduleDetailScreen> createState() =>
      _WearScheduleDetailScreenState();
}

class _WearScheduleDetailScreenState
    extends ConsumerState<WearScheduleDetailScreen> {
  late DateTime _selectedDate;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _previousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
  }

  void _nextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
  }

  @override
  Widget build(BuildContext context) {
    final shape = ref.watch(wearScreenShapeProvider).requireValue;
    final entries = ref.watch(scheduleEntriesForDateProvider(_selectedDate));
    final theme = Theme.of(context);

    return WearSwipeDismiss(
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: WearScreenLayout(
          topFactor: 0.04,
          child: Column(
            children: [
              Text(
                formatDateShort(_selectedDate),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              Text(
                dayLabelFull(_selectedDate.weekday),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: WearCrownScroll(
                  controller: _scrollController,
                  onBoundaryUp: _previousDay,
                  onBoundaryDown: _nextDay,
                  child: WearVerticalOverscrollPager(
                    onPrevious: _previousDay,
                    onNext: _nextDay,
                    child: entries.isEmpty
                        ? ListView(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            children: [
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 32),
                                  child: Text(
                                    t.schedule.noLessons,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Scrollbar(
                            controller: _scrollController,
                            child: ListView.builder(
                              controller: _scrollController,
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(
                                4,
                                0,
                                4,
                                wearListBottomInset(shape),
                              ),
                              itemCount: entries.length,
                              itemBuilder: (context, index) =>
                                  _WearDetailLessonItem(entry: entries[index]),
                            ),
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

class _WearDetailLessonItem extends StatelessWidget {
  const _WearDetailLessonItem({required this.entry});

  final ScheduleEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sColor = entry.event.eventTypesId > 0
        ? subjectColor(entry.event.eventTypesId)
        : theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: entry.changeType != null
            ? theme.colorScheme.errorContainer.withValues(alpha: 0.2)
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 28,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: entry.isCancelled ? theme.colorScheme.error : sColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.subjectName ??
                      '${t.schedule.lessonFallback} ${entry.event.number}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    decoration: entry.isCancelled
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (entry.teacherName != null)
                  Text(
                    entry.teacherName!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                Row(
                  children: [
                    if (entry.roomName != null)
                      Text(
                        entry.roomName!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (entry.roomName != null) const SizedBox(width: 4),
                    Text(
                      entry.timeRange,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                if (entry.topic != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      entry.topic!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (entry.changeType != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _changeLabel(entry.changeType!),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 8, // Intentionally small badge
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _changeLabel(ScheduleChangeType type) {
    return switch (type) {
      ScheduleChangeType.cancelled => t.schedule.cancelled,
      ScheduleChangeType.substitution => t.schedule.substitution,
      ScheduleChangeType.roomChanged => t.schedule.roomChanged,
      ScheduleChangeType.added => t.schedule.added,
    };
  }
}
