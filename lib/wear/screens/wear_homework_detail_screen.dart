import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/more/providers/more_providers.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:bsharp/wear/widgets/wear_crown_scroll.dart';
import 'package:bsharp/wear/widgets/wear_screen_layout.dart';
import 'package:bsharp/wear/widgets/wear_swipe_dismiss.dart';

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

  @override
  Widget build(BuildContext context) {
    final shape = ref.watch(wearScreenShapeProvider).requireValue;
    final homework = ref.watch(filteredHomeworksProvider);
    final filter = ref.watch(homeworkFilterProvider);
    final theme = Theme.of(context);

    return WearSwipeDismiss(
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: WearScreenLayout(
          child: Column(
            children: [
              _WearHomeworkFilter(
                filter: filter,
                onChanged: (f) {
                  ref.read(homeworkFilterProvider.notifier).state = f;
                },
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
                    : WearCrownScroll(
                        controller: _scrollController,
                        child: Scrollbar(
                          controller: _scrollController,
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.fromLTRB(4, 0, 4, wearListBottomInset(shape)),
                            itemCount: homework.length,
                            itemBuilder: (context, index) {
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
                                    Text(
                                      hw.subjectName,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
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
                            },
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

class _WearHomeworkFilter extends StatelessWidget {
  const _WearHomeworkFilter({
    required this.filter,
    required this.onChanged,
  });

  final HomeworkFilter filter;
  final ValueChanged<HomeworkFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const filters = HomeworkFilter.values;
    final current = filters.indexOf(filter);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            final prev = (current - 1) % filters.length;
            onChanged(filters[prev]);
          },
          child: Icon(Icons.chevron_left, size: 18, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 4),
        Text(
          _filterLabel(filter),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () {
            final next = (current + 1) % filters.length;
            onChanged(filters[next]);
          },
          child: Icon(Icons.chevron_right, size: 18, color: theme.colorScheme.primary),
        ),
      ],
    );
  }

  String _filterLabel(HomeworkFilter f) {
    return switch (f) {
      HomeworkFilter.upcoming => t.homework.upcoming,
      HomeworkFilter.past => t.homework.past,
      HomeworkFilter.all => t.homework.all,
    };
  }
}
