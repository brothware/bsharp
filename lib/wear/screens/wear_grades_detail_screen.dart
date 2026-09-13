import 'dart:async';

import 'package:bsharp/app/providers/grades_providers.dart';
import 'package:bsharp/domain/entities/resolved_grade.dart';
import 'package:bsharp/domain/entities/term.dart';
import 'package:bsharp/domain/grade_utils.dart';
import 'package:bsharp/domain/schedule_utils.dart';
import 'package:bsharp/domain/translation_utils.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/wear/widgets/wear_fitted_text.dart';
import 'package:bsharp/wear/widgets/wear_period_selector.dart';
import 'package:bsharp/wear/widgets/wear_pinned_header.dart';
import 'package:bsharp/wear/widgets/wear_scaffold.dart';
import 'package:bsharp/wear/widgets/wear_section_route.dart';
import 'package:bsharp/wear/widgets/wear_swipe_dismiss.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WearGradesDetailScreen extends ConsumerStatefulWidget {
  const WearGradesDetailScreen({super.key});

  @override
  ConsumerState<WearGradesDetailScreen> createState() =>
      _WearGradesDetailScreenState();
}

class _WearGradesDetailScreenState
    extends ConsumerState<WearGradesDetailScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _markVisibleGradesAsRead(),
    );
  }

  void _markVisibleGradesAsRead() {
    final subjectGrades = ref.read(subjectGradesProvider);
    final newIds = ref.read(newGradeIdsProvider);
    final notifier = ref.read(newGradeIdsProvider.notifier);
    for (final sg in subjectGrades) {
      for (final g in sg.grades) {
        if (newIds.contains(g.id)) {
          unawaited(notifier.markAsRead(g.id));
        }
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjectGrades = ref.watch(subjectGradesProvider);
    final terms = ref.watch(termsProvider);
    final currentTerm = ref.watch(currentTermProvider);
    final theme = Theme.of(context);

    return WearSwipeDismiss(
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: WearScaffold(
          scrollController: _scrollController,
          child: Column(
            children: [
              if (terms.length > 1)
                WearPinnedHeader(
                  child: _WearTermPeriodSelector(
                    terms: terms,
                    currentTerm: currentTerm,
                    onChanged: (id) {
                      ref.read(selectedTermIdProvider.notifier).value = id;
                    },
                  ),
                ),
              Expanded(
                child: subjectGrades.isEmpty
                    ? Center(
                        child: Text(
                          t.grades.noGrades,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                        itemCount: subjectGrades.length,
                        itemBuilder: (context, index) =>
                            _WearSubjectSection(sg: subjectGrades[index]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WearTermPeriodSelector extends StatelessWidget {
  const _WearTermPeriodSelector({
    required this.terms,
    required this.currentTerm,
    required this.onChanged,
  });

  final List<Term> terms;
  final Term? currentTerm;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final ct = currentTerm;
    final currentIndex = ct != null
        ? terms.indexWhere((t) => t.id == ct.id)
        : 0;

    final currentTermName = currentTerm?.name;

    return WearPeriodSelector(
      label: currentTermName != null ? translateTermName(currentTermName) : '',
      onPrevious: () {
        final prev = (currentIndex - 1) % terms.length;
        onChanged(terms[prev].id);
      },
      onNext: () {
        final next = (currentIndex + 1) % terms.length;
        onChanged(terms[next].id);
      },
    );
  }
}

class _WearSubjectSection extends StatelessWidget {
  const _WearSubjectSection({required this.sg});

  final SubjectGrades sg;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avg = sg.weightedAverage;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: WearFittedText(
                  sg.subjectName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              if (avg != null)
                Text(
                  formatAverage(avg),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: sg.grades.map((g) {
              final color = gradeColor(
                g.effectiveValue,
                brightness: theme.brightness,
              );
              return InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => pushWearSection(
                  context,
                  (_) => WearGradeDetailScreen(
                    grade: g,
                    subjectName: sg.subjectName,
                  ),
                ),
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 28,
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    g.displayValue,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class WearGradeDetailScreen extends StatelessWidget {
  const WearGradeDetailScreen({
    required this.grade,
    required this.subjectName,
    super.key,
  });

  final ResolvedGrade grade;
  final String subjectName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = gradeColor(
      grade.effectiveValue,
      brightness: theme.brightness,
    );
    final description = grade.description;

    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        Center(
          child: Container(
            constraints: const BoxConstraints(minWidth: 56, minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              grade.displayValue,
              style: theme.textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            subjectName,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Center(
          child: Text(
            translateGradeName(grade.displayValue),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _WearGradeDetailRow(
          label: t.grades.category,
          value: translateGradeCategory(grade.categoryName),
        ),
        _WearGradeDetailRow(
          label: t.grades.weight,
          value: grade.weight.toString(),
        ),
        _WearGradeDetailRow(
          label: t.grades.date,
          value: formatDateShort(grade.date),
        ),
        if (description != null && description.isNotEmpty)
          _WearGradeDetailRow(
            label: t.grades.description,
            value: description,
          ),
      ],
    );
  }
}

class _WearGradeDetailRow extends StatelessWidget {
  const _WearGradeDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(value, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
