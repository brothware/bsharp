import 'dart:async';

import 'package:bsharp/app/account_providers.dart';
import 'package:bsharp/app/child_provider.dart';
import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/data/data_sources/local/account_storage.dart';
import 'package:bsharp/domain/entities/student.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChildSwitcher extends ConsumerWidget {
  const ChildSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeStudentProvider);
    final allEntries = ref.watch(allStudentsProvider);

    if (active == null || active.name.isEmpty) {
      return const Text('BSharp');
    }

    if (allEntries.length <= 1) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 14,
            child: Text(active.name[0], style: const TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
          Text(
            '${active.name} ${active.surname}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: () => _showStudentSwitcher(context, ref, active, allEntries),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 14,
            child: Text(active.name[0], style: const TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
          Text(
            '${active.name} ${active.surname}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }

  void _showStudentSwitcher(
    BuildContext context,
    WidgetRef ref,
    Student active,
    List<StudentEntry> entries,
  ) {
    final accounts = ref.read(providerAccountsProvider).value ?? [];
    final hasMultipleAccounts = accounts.length > 1;

    unawaited(
      showModalBottomSheet<void>(
        context: context,
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    t.accounts.switchStudent,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (hasMultipleAccounts)
                  ..._buildGroupedList(
                    sheetContext,
                    ref,
                    active,
                    entries,
                    accounts,
                  )
                else
                  ..._buildFlatList(sheetContext, ref, active, entries),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildGroupedList(
    BuildContext context,
    WidgetRef ref,
    Student active,
    List<StudentEntry> entries,
    List<dynamic> accounts,
  ) {
    final grouped = <String, List<StudentEntry>>{};
    for (final entry in entries) {
      final key = entry.account.id;
      grouped.putIfAbsent(key, () => []).add(entry);
    }

    final widgets = <Widget>[];
    for (final accountEntries in grouped.values) {
      final account = accountEntries.first.account;
      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            account.schoolName ?? account.slug,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
      for (final entry in accountEntries) {
        final isSelected = entry.student.id == active.id;
        widgets.add(
          _StudentTile(
            name: '${entry.student.name} ${entry.student.surname}',
            initial: entry.student.name.isNotEmpty
                ? entry.student.name[0]
                : '?',
            isSelected: isSelected,
            onTap: () {
              Navigator.of(context).pop();
              _switchToStudent(ref, entry);
            },
          ),
        );
      }
    }
    return widgets;
  }

  List<Widget> _buildFlatList(
    BuildContext context,
    WidgetRef ref,
    Student active,
    List<StudentEntry> entries,
  ) {
    return [
      for (final entry in entries)
        _StudentTile(
          name: '${entry.student.name} ${entry.student.surname}',
          initial: entry.student.name.isNotEmpty ? entry.student.name[0] : '?',
          isSelected: entry.student.id == active.id,
          onTap: () {
            Navigator.of(context).pop();
            _switchToStudent(ref, entry);
          },
        ),
    ];
  }

  void _switchToStudent(WidgetRef ref, StudentEntry entry) {
    unawaited(
      ref
          .read(activeSelectionProvider.notifier)
          .select(
            ActiveSelection(
              accountId: entry.account.id,
              studentId: entry.student.id,
            ),
          ),
    );
    unawaited(ref.read(syncStatusProvider.notifier).sync());
  }
}

class _StudentTile extends StatelessWidget {
  const _StudentTile({
    required this.name,
    required this.initial,
    required this.isSelected,
    required this.onTap,
  });

  final String name;
  final String initial;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 14,
        child: Text(initial, style: const TextStyle(fontSize: 12)),
      ),
      title: Text(name),
      trailing: isSelected
          ? Icon(
              Icons.check,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: onTap,
    );
  }
}
