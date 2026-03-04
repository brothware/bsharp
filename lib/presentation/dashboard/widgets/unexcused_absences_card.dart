import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/attendance/providers/attendance_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class UnexcusedAbsencesCard extends ConsumerWidget {
  const UnexcusedAbsencesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final absences = ref.watch(staleUnexcusedAbsencesProvider);
    if (absences.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: cs.errorContainer,
      child: InkWell(
        onTap: () => StatefulNavigationShell.of(context).goBranch(3),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cs.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '${absences.length}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: cs.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.dashboard.unexcusedAbsences,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: cs.onErrorContainer,
                      ),
                    ),
                    Text(
                      t.dashboard.unexcusedCount(count: absences.length),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onErrorContainer.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: cs.onErrorContainer.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
