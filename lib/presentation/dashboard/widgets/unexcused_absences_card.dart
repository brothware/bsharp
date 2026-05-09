import 'package:bsharp/domain/schedule_utils.dart';
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => StatefulNavigationShell.of(context).goBranch(3),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
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
          for (final absence in absences)
            _AbsenceRow(key: ValueKey(absence.attendance.id), absence: absence),
        ],
      ),
    );
  }
}

class _AbsenceRow extends ConsumerWidget {
  const _AbsenceRow({required this.absence, super.key});

  final UnexcusedAbsence absence;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Dismissible(
      key: ValueKey('absence-${absence.attendance.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: cs.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Icon(Icons.visibility_off, color: cs.onError),
      ),
      onDismissed: (_) async {
        await ref
            .read(ignoredAttendanceDaoProvider)
            ?.markIgnored(absence.attendance.id);
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
        child: Row(
          children: [
            Text(
              formatDateShort(absence.eventDate),
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onErrorContainer.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                absence.subjectName ?? t.attendance.unexcusedLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onErrorContainer,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              tooltip: t.attendance.ignoreAbsence,
              icon: Icon(Icons.visibility_off_outlined, color: cs.error),
              onPressed: () => _confirmIgnore(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmIgnore(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.attendance.ignoreAbsenceConfirmTitle),
        content: Text(t.attendance.ignoreAbsenceConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.attendance.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.attendance.ignore),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(ignoredAttendanceDaoProvider)
        ?.markIgnored(absence.attendance.id);
  }
}
