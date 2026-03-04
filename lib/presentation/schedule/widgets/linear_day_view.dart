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
      (minutes - _startHour * 60) / 60 * _hourHeight;

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(timelineItemsForDateProvider(widget.date));
    final theme = Theme.of(context);

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        height: _totalHeight,
        child: Stack(
          children: [
            for (var h = _startHour; h <= _endHour; h++) ...[
              Positioned(
                top: (h - _startHour) * _hourHeight,
                left: 0,
                right: 0,
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
            ],
            for (final item in items) _buildEventCard(context, item),
            if (_isToday) _buildTimeIndicator(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, TimelineItem item) {
    final startMin = _parseMinutes(item.startTime);
    final endMin = _parseMinutes(item.endTime);
    final top = _timeToY(startMin.toDouble());
    final height = ((endMin - startMin) / 60 * _hourHeight).clamp(
      24.0,
      _totalHeight,
    );
    final theme = Theme.of(context);

    return Positioned(
      top: top,
      left: _leftMargin + 12,
      right: 8,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => widget.onItemTap(item),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: item.displayColor),
              Expanded(
                child: Container(
                  color: item.displayColor.withValues(alpha: 0.15),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          item.displayTitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
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
              ),
            ],
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
