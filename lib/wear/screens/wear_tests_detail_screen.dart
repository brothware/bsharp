import 'package:bsharp/app/providers/more_providers.dart';
import 'package:bsharp/domain/entities/portal.dart';
import 'package:bsharp/domain/portal_date_utils.dart';
import 'package:bsharp/domain/translation_utils.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/wear/widgets/wear_fitted_text.dart';
import 'package:bsharp/wear/widgets/wear_list_item.dart';
import 'package:bsharp/wear/widgets/wear_scaffold.dart';
import 'package:bsharp/wear/widgets/wear_swipe_dismiss.dart';
import 'package:bsharp/wear/widgets/wear_tile_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WearTestsDetailScreen extends ConsumerStatefulWidget {
  const WearTestsDetailScreen({super.key});

  @override
  ConsumerState<WearTestsDetailScreen> createState() =>
      _WearTestsDetailScreenState();
}

class _WearTestsDetailScreenState extends ConsumerState<WearTestsDetailScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allTests = ref.watch(testsProvider);
    final upcomingIds = ref
        .watch(upcomingTestsProvider)
        .map((t) => t.id)
        .toSet();
    final theme = Theme.of(context);

    final sorted = List<PortalTest>.from(allTests)
      ..sort(
        (a, b) => parsePortalDate(b.date).compareTo(parsePortalDate(a.date)),
      );

    return WearSwipeDismiss(
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: WearScaffold(
          scrollController: _scrollController,
          child: Column(
            children: [
              WearTileHeader(icon: Icons.quiz_outlined, title: t.tests.title),
              const SizedBox(height: 4),
              Expanded(
                child: sorted.isEmpty
                    ? Center(
                        child: Text(
                          t.tests.noTests,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                        itemCount: sorted.length,
                        itemBuilder: wearScaledItems(_scrollController, (
                          context,
                          index,
                        ) {
                          final test = sorted[index];
                          final isUpcoming = upcomingIds.contains(test.id);
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: isUpcoming
                                  ? theme.colorScheme.primaryContainer
                                        .withValues(alpha: 0.2)
                                  : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                WearFittedText(
                                  translateSubjectName(test.subjectName),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  test.date,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                if (test.title != null)
                                  WearFittedText(
                                    test.title!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                if (test.description != null)
                                  Text(
                                    test.description!,
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
