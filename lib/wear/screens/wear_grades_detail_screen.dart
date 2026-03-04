import 'package:bsharp/domain/entities/term.dart';
import 'package:bsharp/domain/grade_utils.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/grades/providers/grades_providers.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:bsharp/wear/widgets/wear_crown_scroll.dart';
import 'package:bsharp/wear/widgets/wear_screen_layout.dart';
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
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shape = ref.watch(wearScreenShapeProvider).requireValue;
    final subjectGrades = ref.watch(subjectGradesProvider);
    final terms = ref.watch(termsProvider);
    final currentTerm = ref.watch(currentTermProvider);
    final theme = Theme.of(context);

    return WearSwipeDismiss(
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: WearScreenLayout(
          child: Column(
            children: [
              if (terms.length > 1)
                _WearTermSelector(
                  terms: terms,
                  currentTerm: currentTerm,
                  onChanged: (id) {
                    ref.read(selectedTermIdProvider.notifier).state = id;
                  },
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
                    : WearCrownScroll(
                        controller: _scrollController,
                        child: Scrollbar(
                          controller: _scrollController,
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.fromLTRB(
                              4,
                              0,
                              4,
                              wearListBottomInset(shape),
                            ),
                            itemCount: subjectGrades.length,
                            itemBuilder: (context, index) =>
                                _WearSubjectSection(sg: subjectGrades[index]),
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

class _WearTermSelector extends ConsumerWidget {
  const _WearTermSelector({
    required this.terms,
    required this.currentTerm,
    required this.onChanged,
  });

  final List<Term> terms;
  final Term? currentTerm;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ct = currentTerm;
    final currentIndex = ct != null
        ? terms.indexWhere((t) => t.id == ct.id)
        : 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            final prev = (currentIndex - 1) % terms.length;
            onChanged(terms[prev].id);
          },
          child: Icon(
            Icons.chevron_left,
            size: 18,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            currentTerm?.name ?? '',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () {
            final next = (currentIndex + 1) % terms.length;
            onChanged(terms[next].id);
          },
          child: Icon(
            Icons.chevron_right,
            size: 18,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
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
                child: Text(
                  sg.subjectName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
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
            children: sg.resolvedMarks.map((rm) {
              final color = gradeColor(rm.effectiveValue);
              return Container(
                constraints: const BoxConstraints(minWidth: 40, minHeight: 28),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  rm.displayValue,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
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
