import 'package:bsharp/app/providers/more_providers.dart';
import 'package:bsharp/domain/schedule_utils.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/wear/wear_summary_utils.dart';
import 'package:bsharp/wear/widgets/wear_tile_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _dueSoonWindowDays = 7;

class WearHomeworkTile extends ConsumerWidget {
  const WearHomeworkTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homework = ref.watch(upcomingHomeworkProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        WearTileHeader(icon: Icons.assignment, title: t.homework.title),
        if (homework.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 28,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t.homework.noHomework,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: homework.take(3).length,
              itemBuilder: (context, index) {
                final hw = homework[index];
                final sColor = subjectColor(
                  hw.subjectName,
                  brightness: theme.brightness,
                );
                final isDueSoon = isDateWithinDays(
                  hw.dueDate,
                  _dueSoonWindowDays,
                );
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: isDueSoon
                        ? theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.2,
                          )
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hw.subjectName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: sColor,
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
                        hw.content,
                        style: theme.textTheme.labelSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
