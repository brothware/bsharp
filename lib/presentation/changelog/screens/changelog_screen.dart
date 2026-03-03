import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/domain/entities/portal.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/more/providers/more_providers.dart';

class ChangelogScreen extends ConsumerWidget {
  const ChangelogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: t.changelog.gradesTab),
              Tab(text: t.changelog.attendanceTab),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _ChangelogTab(
                  groupedProvider: groupedGradeChangelogProvider,
                  isGrade: true,
                ),
                _ChangelogTab(
                  groupedProvider: groupedAttendanceChangelogProvider,
                  isGrade: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangelogTab extends ConsumerWidget {
  const _ChangelogTab({required this.groupedProvider, required this.isGrade});

  final Provider<Map<String, List<PortalChangelog>>> groupedProvider;
  final bool isGrade;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grouped = ref.watch(groupedProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(syncStatusProvider.notifier).sync(),
      child: grouped.isEmpty
          ? _EmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: grouped.length,
              itemBuilder: (context, index) {
                final date = grouped.keys.elementAt(index);
                final entries = grouped[date]!;
                return _DateGroup(
                  date: date,
                  entries: entries,
                  isGrade: isGrade,
                );
              },
            ),
    );
  }
}

class _DateGroup extends StatelessWidget {
  const _DateGroup({
    required this.date,
    required this.entries,
    required this.isGrade,
  });

  final String date;
  final List<PortalChangelog> entries;
  final bool isGrade;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(
            date,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        for (final entry in entries)
          Card(
            child: ListTile(
              leading: Icon(
                _actionIcon(entry.action),
                color: _actionColor(entry.action),
              ),
              title: Text(
                '${entry.newName} — ${entry.subjectName}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (entry.newAdditionalInfo.isNotEmpty)
                    Text(
                      entry.newAdditionalInfo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    '${_actionLabel(entry.action, isGrade)} · ${entry.user}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _actionColor(entry.action),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  static IconData _actionIcon(String action) {
    return switch (action) {
      'I' => Icons.add_circle_outline,
      'U' => Icons.edit_outlined,
      'D' => Icons.remove_circle_outline,
      _ => Icons.info_outline,
    };
  }

  static Color _actionColor(String action) {
    return switch (action) {
      'I' => const Color(0xFF4CAF50),
      'U' => const Color(0xFF2196F3),
      'D' => const Color(0xFFF44336),
      _ => const Color(0xFF607D8B),
    };
  }

  static String _actionLabel(String action, bool isGrade) {
    if (isGrade) {
      return switch (action) {
        'I' => t.changelog.gradeAdded,
        'U' => t.changelog.gradeUpdated,
        'D' => t.changelog.gradeDeleted,
        _ => action,
      };
    }
    return switch (action) {
      'I' => t.changelog.attendanceAdded,
      'U' => t.changelog.attendanceUpdated,
      'D' => t.changelog.attendanceDeleted,
      _ => action,
    };
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
          Icons.history_outlined,
          size: 64,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 16),
        Text(
          t.changelog.noChanges,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
      ],
    );
  }
}
