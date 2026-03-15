import 'dart:async';

import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/domain/entities/portal.dart';
import 'package:bsharp/domain/translation_utils.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/more/providers/more_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeworkScreen extends ConsumerWidget {
  const HomeworkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: RefreshIndicator(
        onRefresh: () => ref.read(syncStatusProvider.notifier).sync(),
        child: Column(
          children: [
            TabBar(
              tabs: [
                Tab(text: t.homework.upcoming),
                Tab(text: t.homework.past),
                Tab(text: t.homework.all),
              ],
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant,
              indicatorSize: TabBarIndicatorSize.label,
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  _HomeworkList(filter: HomeworkFilter.upcoming),
                  _HomeworkList(filter: HomeworkFilter.past),
                  _HomeworkList(filter: HomeworkFilter.all),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeworkList extends ConsumerWidget {
  const _HomeworkList({required this.filter});

  final HomeworkFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(homeworksProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final filtered = switch (filter) {
      HomeworkFilter.upcoming =>
        all
            .where(
              (h) =>
                  _parseDate(h.dueDate).isAfter(today) ||
                  _parseDate(h.dueDate).isAtSameMomentAs(today),
            )
            .toList(),
      HomeworkFilter.past =>
        all.where((h) => _parseDate(h.dueDate).isBefore(today)).toList(),
      HomeworkFilter.all => all,
    };

    final sorted = [...filtered]
      ..sort(
        (a, b) => _parseDate(a.dueDate).compareTo(_parseDate(b.dueDate)),
      );

    final grouped = <String, List<PortalHomework>>{};
    for (final hw in sorted) {
      grouped.putIfAbsent(hw.dueDate, () => []).add(hw);
    }

    if (grouped.isEmpty) {
      return _EmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final date = grouped.keys.elementAt(index);
        final items = grouped[date]!;
        return _DateGroup(date: date, homeworks: items);
      },
    );
  }

  DateTime _parseDate(String date) {
    try {
      return DateTime.parse(date);
    } on FormatException {
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
    unawaited(
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
