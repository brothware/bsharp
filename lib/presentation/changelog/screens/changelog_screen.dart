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
    final grouped = ref.watch(groupedChangelogProvider);

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
                return _DateGroup(date: date, entries: entries);
              },
            ),
    );
  }
}

class _DateGroup extends StatelessWidget {
  const _DateGroup({required this.date, required this.entries});

  final String date;
  final List<PortalChangelog> entries;

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
                _changeIcon(entry.type),
                color: _changeColor(entry.type),
              ),
              title: Text(
                entry.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                _changeLabel(entry.type),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: _changeColor(entry.type),
                ),
              ),
            ),
          ),
      ],
    );
  }

  static IconData _changeIcon(String type) {
    return switch (type.toLowerCase()) {
      'grade' || 'mark' || 'ocena' => Icons.grade_outlined,
      'attendance' || 'frekwencja' => Icons.event_available_outlined,
      'message' || 'wiadomość' => Icons.mail_outline,
      'schedule' || 'plan' => Icons.calendar_today_outlined,
      'homework' || 'zadanie' => Icons.assignment_outlined,
      'test' || 'sprawdzian' => Icons.quiz_outlined,
      _ => Icons.info_outline,
    };
  }

  static Color _changeColor(String type) {
    return switch (type.toLowerCase()) {
      'grade' || 'mark' || 'ocena' => const Color(0xFF2196F3),
      'attendance' || 'frekwencja' => const Color(0xFF4CAF50),
      'message' || 'wiadomość' => const Color(0xFF9C27B0),
      'schedule' || 'plan' => const Color(0xFFFFA726),
      'homework' || 'zadanie' => const Color(0xFFE91E63),
      'test' || 'sprawdzian' => const Color(0xFFFF5722),
      _ => const Color(0xFF607D8B),
    };
  }

  static String _changeLabel(String type) {
    return switch (type.toLowerCase()) {
      'grade' || 'mark' || 'ocena' => t.changelog.grade,
      'attendance' || 'frekwencja' => t.changelog.attendanceLabel,
      'message' || 'wiadomość' => t.changelog.messageLabel,
      'schedule' || 'plan' => t.changelog.scheduleLabel,
      'homework' || 'zadanie' => t.changelog.homeworkLabel,
      'test' || 'sprawdzian' => t.changelog.testLabel,
      _ => type,
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
