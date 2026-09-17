import 'dart:math' as math;

import 'package:bsharp/app/providers/dashboard_providers.dart';
import 'package:bsharp/app/providers/schedule_providers.dart';
import 'package:bsharp/domain/schedule_utils.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/wear/wear_app.dart';
import 'package:bsharp/wear/widgets/wear_fitted_text.dart';
import 'package:bsharp/wear/widgets/wear_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WearLessonHero extends ConsumerStatefulWidget {
  const WearLessonHero({super.key});

  @override
  ConsumerState<WearLessonHero> createState() => _WearLessonHeroState();
}

class _WearLessonHeroState extends ConsumerState<WearLessonHero> {
  int _page = 0;

  void _showNextAlternative() => setState(() => _page++);

  @override
  Widget build(BuildContext context) {
    final resolvedEvents = ref.watch(resolvedEventsProvider);
    final todayLessons = ref.watch(todayLessonsProvider);
    final lesson = ref.watch(currentLessonProvider);
    final now = ref.watch(minuteTickProvider);
    final isRound = WearDisplayScope.of(context).isRound;

    if (resolvedEvents.isEmpty) {
      return _WearHeroBody(
        eyebrow: t.wearDashboard.noData,
        title: t.wearDashboard.syncPrompt,
        room: null,
        countdown: null,
        progress: null,
        isRound: isRound,
      );
    }

    if (lesson.current.isNotEmpty) {
      final page = _page % lesson.current.length;
      final entry = lesson.current[page];
      return _WearHeroBody(
        eyebrow: t.wearDashboard.now,
        title: entry.displayName,
        room: entry.roomName,
        countdown: t.wearDashboard.endsIn(n: _minutesUntil(entry.endTime, now)),
        progress: _lessonProgress(entry, now),
        isRound: isRound,
        pageCount: lesson.current.length,
        pageIndex: page,
        onShowNext: _showNextAlternative,
      );
    }

    if (lesson.next.isNotEmpty) {
      final page = _page % lesson.next.length;
      final entry = lesson.next[page];
      return _WearHeroBody(
        eyebrow: t.wearDashboard.next,
        title: entry.displayName,
        room: entry.roomName,
        countdown: t.wearDashboard.startsIn(
          n: _minutesUntil(entry.startTime, now),
        ),
        progress: null,
        isRound: isRound,
        pageCount: lesson.next.length,
        pageIndex: page,
        onShowNext: _showNextAlternative,
      );
    }

    final nextDay = ref.watch(nextSchoolDayProvider);
    final firstLesson = nextDay == null
        ? null
        : _firstLesson(ref.watch(scheduleEntriesForDateProvider(nextDay)));

    if (lesson.allEnded) {
      return _WearHeroBody(
        eyebrow: t.wearDashboard.tomorrow,
        title: firstLesson?.displayName ?? t.wearDashboard.syncPrompt,
        room: firstLesson?.roomName,
        countdown: firstLesson?.timeRange,
        progress: null,
        isRound: isRound,
      );
    }

    if (todayLessons.isEmpty) {
      return _WearHeroBody(
        eyebrow: t.wearDashboard.noLessons,
        title: firstLesson?.displayName ?? t.wearDashboard.syncPrompt,
        room: firstLesson?.roomName,
        countdown: firstLesson == null
            ? null
            : '${dayLabel(nextDay!.weekday)} ${firstLesson.timeRange}',
        progress: null,
        isRound: isRound,
      );
    }

    return _WearHeroBody(
      eyebrow: t.wearDashboard.noData,
      title: t.wearDashboard.syncPrompt,
      room: null,
      countdown: null,
      progress: null,
      isRound: isRound,
    );
  }

  ScheduleEntry? _firstLesson(List<ScheduleEntry> entries) {
    for (final entry in entries) {
      if (!entry.isCancelled) return entry;
    }
    return null;
  }

  int _minutesUntil(String time, DateTime now) {
    final target = parseTimeMinutes(time);
    if (target == null) return 0;
    final nowMinutes = now.hour * 60 + now.minute;
    return (target - nowMinutes).clamp(0, 24 * 60);
  }

  double? _lessonProgress(ScheduleEntry entry, DateTime now) {
    final start = parseTimeMinutes(entry.startTime);
    final end = parseTimeMinutes(entry.endTime);
    if (start == null || end == null || end <= start) return null;
    final nowMinutes = now.hour * 60 + now.minute;
    return ((nowMinutes - start) / (end - start)).clamp(0.0, 1.0);
  }
}

class _WearHeroBody extends StatelessWidget {
  const _WearHeroBody({
    required this.eyebrow,
    required this.title,
    required this.room,
    required this.countdown,
    required this.progress,
    required this.isRound,
    this.pageCount = 1,
    this.pageIndex = 0,
    this.onShowNext,
  });

  final String eyebrow;
  final String title;
  final String? room;
  final String? countdown;
  final double? progress;
  final bool isRound;
  final int pageCount;
  final int pageIndex;
  final VoidCallback? onShowNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final textColumn = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          eyebrow,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        WearFittedText(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (room case final room?) ...[
          const SizedBox(height: 2),
          Text(
            room,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (countdown case final countdown?) ...[
          const SizedBox(height: 2),
          WearFittedText(
            countdown,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (pageCount > 1) ...[
          const SizedBox(height: 4),
          _AlternativeDots(count: pageCount, index: pageIndex),
        ],
      ],
    );

    return _tappable(_layout(context, textColumn));
  }

  Widget _tappable(Widget child) {
    if (pageCount < 2 || onShowNext == null) return child;
    return GestureDetector(
      onTap: onShowNext,
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }

  Widget _layout(BuildContext context, Widget textColumn) {
    final theme = Theme.of(context);

    if (progress == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: textColumn,
      );
    }

    if (isRound) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: SizedBox(
          width: 148,
          height: 148,
          child: CustomPaint(
            painter: _ProgressRingPainter(
              progress: progress!,
              color: theme.colorScheme.primary,
              backgroundColor: wearTrackColor(theme.colorScheme),
            ),
            child: Center(child: textColumn),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          textColumn,
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: wearTrackColor(theme.colorScheme),
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlternativeDots extends StatelessWidget {
  const _AlternativeDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var dot = 0; dot < count; dot++)
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dot == index
                  ? cs.primary
                  : cs.onSurfaceVariant.withValues(alpha: 0.35),
            ),
          ),
      ],
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  _ProgressRingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  final double progress;
  final Color color;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 6.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

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

    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) =>
      progress != oldDelegate.progress || color != oldDelegate.color;
}
