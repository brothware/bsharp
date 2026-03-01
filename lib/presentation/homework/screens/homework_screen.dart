import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/domain/entities/portal.dart';
import 'package:bsharp/domain/translation_utils.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/more/providers/more_providers.dart';

class HomeworkScreen extends ConsumerWidget {
  const HomeworkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grouped = ref.watch(groupedHomeworksProvider);
    final filter = ref.watch(homeworkFilterProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(syncStatusProvider.notifier).sync(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<HomeworkFilter>(
              segments: [
                ButtonSegment(
                  value: HomeworkFilter.upcoming,
                  label: Text(t.homework.upcoming),
                ),
                ButtonSegment(
                  value: HomeworkFilter.past,
                  label: Text(t.homework.past),
                ),
                ButtonSegment(
                  value: HomeworkFilter.all,
                  label: Text(t.homework.all),
                ),
              ],
              selected: {filter},
              onSelectionChanged: (s) =>
                  ref.read(homeworkFilterProvider.notifier).state = s.first,
            ),
          ),
          Expanded(
            child: grouped.isEmpty
                ? _EmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: grouped.length,
                    itemBuilder: (context, index) {
                      final date = grouped.keys.elementAt(index);
                      final items = grouped[date]!;
                      return _DateGroup(date: date, homeworks: items);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _DateGroup extends StatelessWidget {
  const _DateGroup({required this.date, required this.homeworks});

  final String date;
  final List<PortalHomework> homeworks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(
            t.homework.dueDate(date: date),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        for (final hw in homeworks)
          Card(
            child: ListTile(
              leading: Icon(
                Icons.assignment_outlined,
                color: theme.colorScheme.primary,
              ),
              title: Text(translateSubjectName(hw.subjectName)),
              subtitle: Text(
                hw.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                t.homework.assignedDate(date: hw.date),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              isThreeLine: true,
              onTap: () => _showDetail(context, hw),
            ),
          ),
      ],
    );
  }

  void _showDetail(BuildContext context, PortalHomework hw) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              translateSubjectName(hw.subjectName),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(t.homework.assignedDate(date: hw.date)),
            Text(t.homework.dueDate(date: hw.dueDate)),
            const SizedBox(height: 16),
            Text(hw.content),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      children: [
        const SizedBox(height: 80),
        Icon(
          Icons.assignment_outlined,
          size: 64,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 16),
        Text(
          t.homework.noHomework,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
      ],
    );
  }
}
