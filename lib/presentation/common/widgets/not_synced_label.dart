import 'package:bsharp/app/sync_health_provider.dart';
import 'package:bsharp/domain/school_data_provider.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotSyncedScope extends StatelessWidget {
  const NotSyncedScope({
    required this.area,
    required this.child,
    this.onRetry,
    super.key,
  });

  final DataProviderCapability area;
  final Widget child;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        NotSyncedLabel(area: area, onRetry: onRetry),
        Expanded(child: child),
      ],
    );
  }
}

class NotSyncedLabel extends ConsumerWidget {
  const NotSyncedLabel({required this.area, this.onRetry, super.key});

  final DataProviderCapability area;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(syncHealthProvider);
    if (!health.isStale(area)) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final lastSyncedAt = health.lastSyncedAt[area];
    final text = lastSyncedAt == null
        ? t.common.notSynced
        : t.common.notSyncedSince(time: _formatTime(lastSyncedAt));

    return Material(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Icon(
              Icons.sync_problem_outlined,
              size: 18,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: Text(t.common.retry)),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return t.common.agoJustNow;
    if (diff.inMinutes < 60) return t.common.agoMinutes(n: diff.inMinutes);
    if (diff.inHours < 24) return t.common.agoHours(n: diff.inHours);
    return '${time.day.toString().padLeft(2, '0')}.'
        '${time.month.toString().padLeft(2, '0')} '
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }
}
