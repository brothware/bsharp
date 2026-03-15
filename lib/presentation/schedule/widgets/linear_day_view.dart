import 'dart:async';

import 'package:bsharp/domain/schedule_utils.dart';
import 'package:bsharp/domain/timeline_item.dart';
import 'package:bsharp/presentation/schedule/providers/schedule_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _startHour = 7;
const _endHour = 20;
const _hourHeight = 80.0;
const double _totalHeight = (_endHour - _startHour) * _hourHeight;
const _leftMargin = 52.0;
const _verticalPadding = 12.0;

class _LayoutSlot {
  _LayoutSlot({
    required this.item,
    required this.column,
    required this.totalColumns,
  });

  final TimelineItem item;
  final int column;
  final int totalColumns;
}

List<_LayoutSlot> _computeLayout(List<TimelineItem> items) {
  if (items.isEmpty) return [];

  int parseMin(String t) {
    final p = t.split(':');
    return p.length >= 2 ? int.parse(p[0]) * 60 + int.parse(p[1]) : 0;
  }

  final sorted = [...items]
    ..sort(
      (a, b) => parseMin(a.startTime).compareTo(parseMin(b.startTime)),
    );

  final groups = <List<TimelineItem>>[];
  for (final item in sorted) {
    final start = parseMin(item.startTime);
    final end = parseMin(item.endTime);
    var placed = false;
    for (final group in groups) {
      final overlaps = group.any((g) {
        final gStart = parseMin(g.startTime);
        final gEnd = parseMin(g.endTime);
        return start < gEnd && gStart < end;
      });
      if (overlaps) {
        group.add(item);
        placed = true;
        break;
      }
    }
    if (!placed) groups.add([item]);
  }

  final slots = <_LayoutSlot>[];
  for (final group in groups) {
    final columns = <int, List<TimelineItem>>{};
    for (final item in group) {
      final start = parseMin(item.startTime);
      final end = parseMin(item.endTime);
      var col = 0;
      while (columns[col]?.any((g) {
            final gStart = parseMin(g.startTime);
            final gEnd = parseMin(g.endTime);
            return start < gEnd && gStart < end;
          }) ??
          false) {
        col++;
      }
      columns.putIfAbsent(col, () => []).add(item);
    }
    final totalCols = columns.length;
    for (final entry in columns.entries) {
      for (final item in entry.value) {
        slots.add(
          _LayoutSlot(item: item, column: entry.key, totalColumns: totalCols),
        );
      }
    }
  }

  return slots;
}

class LinearDayView extends ConsumerStatefulWidget {
  const LinearDayView({required this.date, required this.onItemTap, super.key});

  final DateTime date;
  final void Function(TimelineItem item) onItemTap;

  @override
  ConsumerState<LinearDayView> createState() => _LinearDayViewState();
}

class _LinearDayViewState extends ConsumerState<LinearDayView> {
  final _scrollController = ScrollController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToNow());
    if (_isToday) {
      _timer = Timer.periodic(
        const Duration(minutes: 1),
        (_) => setState(() {}),
      );
    }
  }

  @override
  void didUpdateWidget(covariant LinearDayView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!isSameDay(oldWidget.date, widget.date)) {
      _timer?.cancel();
      _timer = null;
      if (_isToday) {
        _timer = Timer.periodic(
          const Duration(minutes: 1),
          (_) => setState(() {}),
        );
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToNow());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _isToday => isSameDay(widget.date, DateTime.now());

  void _scrollToNow() {
    if (!_scrollController.hasClients) return;
    final now = DateTime.now();
    if (_isToday) {
      final offset = _timeToY(now.hour * 60.0 + now.minute) - 100;
      _scrollController.jumpTo(
        offset.clamp(0, _scrollController.position.maxScrollExtent),
      );
    } else {
      _scrollController.jumpTo(0);
    }
  }

  double _timeToY(double minutes) =>
      (minutes - _startHour * 60) / 60 * _hourHeight + _verticalPadding;

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(timelineItemsForDateProvider(widget.date));
    final theme = Theme.of(context);

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        height: _totalHeight + _verticalPadding * 2,
        child: Stack(
          children: [
            for (var h = _startHour; h <= _endHour; h++) ...[
              Positioned(
                top: (h - _startHour) * _hourHeight + _verticalPadding,
                left: 0,
                right: 0,
                child: FractionalTranslation(
                  translation: const Offset(0, -0.5),
                  child: Row(
                    children: [
                      SizedBox(
                        width: _leftMargin,
                        child: Text(
                          '${h.toString().padLeft(2, '0')}:00',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Divider(
                          height: 1,
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            for (final slot in _computeLayout(items))
              _buildEventCard(context, slot),
            if (_isToday) _buildTimeIndicator(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, _LayoutSlot slot) {
    final item = slot.item;
    final startMin = _parseMinutes(item.startTime);
    final endMin = _parseMinutes(item.endTime);
    final top = _timeToY(startMin.toDouble());
    final height = ((endMin - startMin) / 60 * _hourHeight).clamp(
      24.0,
      _totalHeight,
    );
    final theme = Theme.of(context);
    final cancelled = item.isCancelled;
    final substitution = item.isSubstitution;
    final itemColor = item.displayColor(brightness: theme.brightness);
    final sideColor = cancelled ? theme.colorScheme.error : itemColor;

    return Positioned(
      top: top,
      left:
          _leftMargin +
          12 +
          slot.column *
              (MediaQuery.of(context).size.width - _leftMargin - 12 - 8 - 24) /
              slot.totalColumns,
      width:
          (MediaQuery.of(context).size.width - _leftMargin - 12 - 8 - 24) /
              slot.totalColumns -
          2,
      height: height,
      child: Opacity(
        opacity: cancelled ? 0.5 : 1.0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: () => widget.onItemTap(item),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: sideColor),
                Expanded(
                  child: Container(
                    color: itemColor.withValues(alpha: 0.15),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  item.displayTitle,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    decoration: cancelled
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (item.displaySubtitle != null && height > 40)
                                Flexible(
                                  child: Text(
                                    item.displaySubtitle!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (substitution)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.swap_horiz,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeIndicator(ThemeData theme) {
    final now = DateTime.now();
    final minutes = now.hour * 60.0 + now.minute;
    final top = _timeToY(minutes);

    return Positioned(
      top: top - 4,
      left: _leftMargin,
      right: 0,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(child: Container(height: 2, color: Colors.red)),
        ],
      ),
    );
  }

  int _parseMinutes(String time) {
    final parts = time.split(':');
    if (parts.length < 2) return 0;
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}
