import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WearStatusLine extends ConsumerWidget {
  const WearStatusLine({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncStatusProvider);
    final theme = Theme.of(context);

    return switch (status) {
      SyncStatus.syncing => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              t.sync.syncing,
              style: theme.textTheme.labelMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      SyncStatus.failed => GestureDetector(
        onTap: () => ref.read(syncStatusProvider.notifier).sync(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 16,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                t.sync.syncFailed,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                t.common.retry,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      SyncStatus.idle ||
      SyncStatus.hydrated ||
      SyncStatus.completed => const SizedBox.shrink(),
    };
  }
}
