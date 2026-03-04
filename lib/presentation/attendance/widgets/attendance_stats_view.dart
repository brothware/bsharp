import 'package:bsharp/domain/attendance_utils.dart';
import 'package:bsharp/domain/entities/sync_action.dart';
import 'package:bsharp/domain/translation_utils.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/attendance/providers/attendance_providers.dart';
import 'package:bsharp/presentation/grades/providers/grades_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AttendanceStatsView extends ConsumerWidget {
  const AttendanceStatsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(attendanceStatsProvider);

    if (stats.totalLessons == 0) {
      return _EmptyStats();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _TermFilterChips(),
        const SizedBox(height: 12),
        _OverallCard(stats: stats),
        const SizedBox(height: 16),
        _DistributionCard(stats: stats),
        const SizedBox(height: 16),
        _TypeBreakdownCard(stats: stats),
      ],
    );
  }
}

class _TermFilterChips extends ConsumerWidget {
  const _TermFilterChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final terms = ref.watch(termsProvider);
    final currentTerm = ref.watch(currentStatsTermProvider);
    final semesters = terms.where((t) => t.type == TermType.semester).toList();

    if (semesters.isEmpty) return const SizedBox.shrink();

    final selectedId = ref.watch(selectedStatsTermIdProvider);
    final isAllSelected = selectedId == 0;

    return Wrap(
      spacing: 8,
      children: [
        ChoiceChip(
          label: Text(t.attendance.fullYear),
          selected: isAllSelected,
          onSelected: (_) {
            ref.read(selectedStatsTermIdProvider.notifier).state = 0;
          },
        ),
        for (final term in semesters)
          ChoiceChip(
            label: Text(translateTermName(term.name)),
            selected: currentTerm?.id == term.id,
            onSelected: (_) {
              ref.read(selectedStatsTermIdProvider.notifier).state = term.id;
            },
          ),
      ],
    );
  }
}

class _EmptyStats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(t.common.noData, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            t.attendance.statsAfterSync,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverallCard extends StatelessWidget {
  const _OverallCard({required this.stats});

  final AttendanceStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentColor = stats.presentPercent >= 90
        ? const Color(0xFF4CAF50)
        : stats.presentPercent >= 75
        ? const Color(0xFFFFA726)
        : const Color(0xFFF44336);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(t.attendance.overall, style: theme.textTheme.titleSmall),
            const SizedBox(height: 16),
            SizedBox(
              width: 120,
              height: 120,
              child: CustomPaint(
                painter: _RingPainter(
                  percent: stats.presentPercent / 100,
                  color: percentColor,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
                child: Center(
                  child: Text(
                    attendancePercentLabel(stats.presentPercent),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: percentColor,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatItem(
                  label: t.attendance.total,
                  value: '${stats.totalLessons}',
                ),
                _StatItem(
                  label: t.attendance.presentCount,
                  value: '${stats.presentCount}',
                  color: const Color(0xFF4CAF50),
                ),
                _StatItem(
                  label: t.attendance.absentCount,
                  value: '${stats.absentCount}',
                  color: const Color(0xFFF44336),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _DistributionCard extends StatelessWidget {
  const _DistributionCard({required this.stats});

  final AttendanceStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final presentFraction = stats.totalLessons > 0
        ? stats.presentCount / stats.totalLessons
        : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.attendance.distribution, style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 24,
                child: Row(
                  children: [
                    if (presentFraction > 0)
                      Expanded(
                        flex: stats.presentCount,
                        child: Container(
                          color: const Color(0xFF4CAF50),
                          alignment: Alignment.center,
                          child: stats.presentCount > 0
                              ? Text(
                                  '${stats.presentCount}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    if (stats.absentCount > 0)
                      Expanded(
                        flex: stats.absentCount,
                        child: Container(
                          color: const Color(0xFFF44336),
                          alignment: Alignment.center,
                          child: Text(
                            '${stats.absentCount}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeBreakdownCard extends StatelessWidget {
  const _TypeBreakdownCard({required this.stats});

  final AttendanceStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sorted = stats.typeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.attendance.byType, style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            for (final entry in sorted)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        translateAttendanceName(entry.key),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      '${entry.value}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.percent,
    required this.color,
    required this.backgroundColor,
  });

  final double percent;
  final Color color;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 10.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -1.5708;
    final sweepAngle = 6.2832 * percent;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      percent != oldDelegate.percent || color != oldDelegate.color;
}
