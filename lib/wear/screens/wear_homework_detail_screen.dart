import 'package:bsharp/app/providers/more_providers.dart';
import 'package:bsharp/domain/translation_utils.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/wear/widgets/wear_fitted_text.dart';
import 'package:bsharp/wear/widgets/wear_list_item.dart';
import 'package:bsharp/wear/widgets/wear_period_selector.dart';
import 'package:bsharp/wear/widgets/wear_pinned_header.dart';
import 'package:bsharp/wear/widgets/wear_scaffold.dart';
import 'package:bsharp/wear/widgets/wear_side_navigation.dart';
import 'package:bsharp/wear/widgets/wear_swipe_dismiss.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WearHomeworkDetailScreen extends ConsumerStatefulWidget {
  const WearHomeworkDetailScreen({super.key});

  @override
  ConsumerState<WearHomeworkDetailScreen> createState() =>
      _WearHomeworkDetailScreenState();
}

class _WearHomeworkDetailScreenState
    extends ConsumerState<WearHomeworkDetailScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _stepFilter(HomeworkFilter current, int delta) {
    const filters = HomeworkFilter.values;
    final next = (filters.indexOf(current) + delta) % filters.length;
    ref.read(homeworkFilterProvider.notifier).value = filters[next];
  }

  @override
  Widget build(BuildContext context) {
    final homework = ref.watch(filteredHomeworksProvider);
    final filter = ref.watch(homeworkFilterProvider);
    final theme = Theme.of(context);

    return WearSwipeDismiss(
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: WearScaffold(
          scrollController: _scrollController,
          edgeContent: WearSideNavigation(
            onPrevious: () => _stepFilter(filter, -1),
            onNext: () => _stepFilter(filter, 1),
            scrollController: _scrollController,
          ),
          child: Column(
            children: [
              WearPinnedHeader(
                child: _WearHomeworkFilterSelector(filter: filter),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: homework.isEmpty
                    ? Center(
                        child: Text(
                          t.homework.noHomework,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                        itemCount: homework.length,
                        itemBuilder: wearScaledItems(_scrollController, (
                          context,
                          index,
                        ) {
                          final hw = homework[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                WearFittedText(
                                  translateSubjectName(hw.subjectName),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  t.homework.dueDate(date: hw.dueDate),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  t.homework.assignedDate(date: hw.date),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  hw.content,
                                  style: theme.textTheme.labelSmall,
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WearHomeworkFilterSelector extends StatelessWidget {
  const _WearHomeworkFilterSelector({required this.filter});

  final HomeworkFilter filter;

  @override
  Widget build(BuildContext context) {
    return WearPeriodSelector(label: _filterLabel(filter));
  }

  String _filterLabel(HomeworkFilter f) {
    return switch (f) {
      HomeworkFilter.upcoming => t.homework.upcoming,
      HomeworkFilter.past => t.homework.past,
      HomeworkFilter.all => t.homework.all,
    };
  }
}
