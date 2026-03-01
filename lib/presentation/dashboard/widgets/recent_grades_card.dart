import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bsharp/domain/grade_utils.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/dashboard/providers/dashboard_providers.dart';
import 'package:bsharp/presentation/grades/providers/grades_providers.dart';

class RecentGradesCard extends ConsumerWidget {
  const RecentGradesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentMarksProvider);
    final average = ref.watch(overallWeightedAverageProvider);
    final newIds = ref.watch(newGradeIdsProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: cs.surfaceContainerLow,
      child: InkWell(
        onTap: () => StatefulNavigationShell.of(context).goBranch(2),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    t.dashboard.recentGrades,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: cs.onSurface,
                    ),
                  ),
                  const Spacer(),
                  if (average != null) _AveragePill(average: average),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (recent.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    t.dashboard.noGrades,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 56,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: recent.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final entry = recent[index];
                      final isNew = newIds.contains(entry.mark.mark.id);
                      return _GradeChip(
                        displayValue: entry.mark.displayValue,
                        subjectName: entry.subjectName,
                        effectiveValue: entry.mark.effectiveValue,
                        isNew: isNew,
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AveragePill extends StatelessWidget {
  const _AveragePill({required this.average});

  final double average;

  @override
  Widget build(BuildContext context) {
    final color = gradeColor(average);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        formatAverage(average),
        style: theme.textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _GradeChip extends StatelessWidget {
  const _GradeChip({
    required this.displayValue,
    required this.subjectName,
    required this.effectiveValue,
    required this.isNew,
  });

  final String displayValue;
  final String subjectName;
  final double? effectiveValue;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = gradeColor(effectiveValue);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                displayValue,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            if (isNew)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: cs.surfaceContainerLow,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 48,
          child: Text(
            subjectName,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontSize: 9,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
