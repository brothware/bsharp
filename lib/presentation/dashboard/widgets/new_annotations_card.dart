import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/more/providers/more_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class NewAnnotationsCard extends ConsumerWidget {
  const NewAnnotationsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadPraises = ref.watch(unreadPraisesCountProvider);
    final unreadRemarks = ref.watch(unreadRemarksCountProvider);
    final count = unreadPraises + unreadRemarks;

    if (count == 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: cs.tertiaryContainer,
      child: InkWell(
        onTap: () => StatefulNavigationShell.of(context).goBranch(5),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Badge(
                label: Text('$count'),
                backgroundColor: cs.tertiary,
                textColor: cs.onTertiary,
                child: Icon(
                  Icons.sticky_note_2_outlined,
                  size: 22,
                  color: cs.onTertiaryContainer,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.dashboard.newAnnotations,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: cs.onTertiaryContainer,
                      ),
                    ),
                    Text(
                      t.dashboard.newAnnotationsCount(count: count),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onTertiaryContainer.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: cs.onTertiaryContainer.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
