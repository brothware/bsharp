import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/domain/entities/portal.dart';
import 'package:bsharp/domain/translation_utils.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/more/providers/more_providers.dart';

class TestsScreen extends ConsumerWidget {
  const TestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tests = ref.watch(testsProvider);
    final upcoming = ref.watch(upcomingTestsProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(syncStatusProvider.notifier).sync(),
      child: tests.isEmpty
          ? _EmptyState()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (upcoming.isNotEmpty) ...[
                  Text(
                    t.tests.upcoming,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final test in upcoming)
                    _TestCard(test: test, isUpcoming: true),
                  const SizedBox(height: 16),
                ],
                if (tests.length > upcoming.length) ...[
                  Text(
                    t.tests.all,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final test in tests)
                    _TestCard(test: test, isUpcoming: false),
                ],
              ],
            ),
    );
  }
}

class _TestCard extends StatelessWidget {
  const _TestCard({required this.test, required this.isUpcoming});

  final PortalTest test;
  final bool isUpcoming;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: isUpcoming
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
          : null,
      child: ListTile(
        leading: Icon(
          Icons.quiz_outlined,
          color: isUpcoming
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(translateSubjectName(test.subjectName)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (test.title != null) Text(test.title!),
            if (test.description != null)
              Text(
                test.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        trailing: Text(
          test.date,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: isUpcoming ? FontWeight.bold : null,
            color: isUpcoming ? theme.colorScheme.primary : null,
          ),
        ),
        isThreeLine: test.description != null,
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
          Icons.quiz_outlined,
          size: 64,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 16),
        Text(
          t.tests.noTests,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
      ],
    );
  }
}
