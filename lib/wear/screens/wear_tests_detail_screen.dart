import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bsharp/domain/entities/portal.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/more/providers/more_providers.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:bsharp/wear/widgets/wear_crown_scroll.dart';
import 'package:bsharp/wear/widgets/wear_screen_layout.dart';
import 'package:bsharp/wear/widgets/wear_swipe_dismiss.dart';
import 'package:bsharp/wear/widgets/wear_tile_header.dart';

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
    final shape = ref.watch(wearScreenShapeProvider).requireValue;
    final allTests = ref.watch(testsProvider);
    final upcomingIds = ref
        .watch(upcomingTestsProvider)
        .map((t) => t.id)
        .toSet();
    final theme = Theme.of(context);

    final sorted = List<PortalTest>.from(allTests)
      ..sort((a, b) => _parseDate(b.date).compareTo(_parseDate(a.date)));

    return WearSwipeDismiss(
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: WearScreenLayout(
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
                            itemCount: sorted.length,
                            itemBuilder: (context, index) {
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
                                    Text(
                                      test.subjectName,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      test.date,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                    if (test.title != null)
                                      Text(
                                        test.title!,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    if (test.description != null)
                                      Text(
                                        test.description!,
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

  DateTime _parseDate(String date) {
    try {
      return DateTime.parse(date);
    } on FormatException catch (_) {
      final parts = date.split('.');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
      return DateTime(2000);
    }
  }
}
