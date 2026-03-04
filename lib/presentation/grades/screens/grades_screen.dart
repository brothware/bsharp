import 'dart:async';

import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/domain/grade_utils.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/grades/providers/grades_providers.dart';
import 'package:bsharp/presentation/grades/widgets/grade_chip.dart';
import 'package:bsharp/presentation/grades/widgets/grade_detail_sheet.dart';
import 'package:bsharp/presentation/grades/widgets/term_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GradesScreen extends ConsumerWidget {
  const GradesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectGrades = ref.watch(subjectGradesProvider);
    final overallWeighted = ref.watch(overallWeightedAverageProvider);
    final overallSimple = ref.watch(overallSimpleAverageProvider);
    final newIds = ref.watch(newGradeIdsProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(syncStatusProvider.notifier).sync(),
      child: subjectGrades.isEmpty
          ? _EmptyState()
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        const Expanded(child: TermSelector()),
                        const SizedBox(width: 8),
                        _AverageChip(
                          label: t.grades.weightedAverageLabel,
                          average: overallWeighted,
                        ),
                        const SizedBox(width: 6),
                        _AverageChip(
                          label: t.grades.simpleAverageLabel,
                          average: overallSimple,
                        ),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final sg = subjectGrades[index];
                    return _SubjectSection(
                      subjectGrades: sg,
                      newGradeIds: newIds,
                    );
                  }, childCount: subjectGrades.length),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 80),
        Icon(
          Icons.grade_outlined,
          size: 64,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 16),
        Text(
          t.grades.noGrades,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          t.grades.noGradesSubtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _AverageChip extends StatelessWidget {
  const _AverageChip({required this.label, required this.average});

  final String label;
  final double? average;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: average != null
            ? gradeColor(average).withValues(alpha: 0.15)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          Text(
            formatAverage(average),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: average != null ? gradeColor(average) : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectSection extends StatelessWidget {
  const _SubjectSection({
    required this.subjectGrades,
    required this.newGradeIds,
  });

  final SubjectGrades subjectGrades;
  final Set<int> newGradeIds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weighted = subjectGrades.weightedAverage;
    final simple = subjectGrades.simpleAverage;

    return ExpansionTile(
      initiallyExpanded: true,
      title: Text(subjectGrades.subjectName, style: theme.textTheme.titleSmall),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (weighted != null || simple != null)
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (weighted != null)
                  Text(
                    '${t.grades.weightedAverageLabel}${formatAverage(weighted)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: gradeColor(weighted),
                    ),
                  ),
                if (simple != null)
                  Text(
                    '${t.grades.simpleAverageLabel}${formatAverage(simple)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: gradeColor(simple),
                    ),
                  ),
              ],
            ),
          const SizedBox(width: 8),
          const Icon(Icons.expand_more),
        ],
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final rm in subjectGrades.resolvedMarks)
                GradeChip(
                  resolvedMark: rm,
                  isNew: newGradeIds.contains(rm.mark.id),
                  onTap: () => _showDetail(context, rm),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDetail(BuildContext context, ResolvedMark rm) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => GradeDetailSheet(
          resolvedMark: rm,
          subjectName: subjectGrades.subjectName,
        ),
      ),
    );
  }
}
