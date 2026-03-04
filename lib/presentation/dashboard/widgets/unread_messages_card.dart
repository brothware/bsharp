import 'package:bsharp/app/router.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/dashboard/providers/dashboard_providers.dart';
import 'package:bsharp/presentation/messages/providers/messages_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class UnreadMessagesCard extends ConsumerWidget {
  const UnreadMessagesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(unreadCountProvider);
    final latest = ref.watch(latestUnreadMessagesProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (count == 0) return const SizedBox.shrink();

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: cs.tertiaryContainer,
      child: InkWell(
        onTap: () => context.push(AppRoutes.messages),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Badge(
                    label: Text('$count'),
                    backgroundColor: cs.tertiary,
                    textColor: cs.onTertiary,
                    child: Icon(
                      Icons.mail_outline,
                      size: 22,
                      color: cs.onTertiaryContainer,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t.dashboard.unreadCount(count: count),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: cs.onTertiaryContainer,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: cs.onTertiaryContainer.withValues(alpha: 0.5),
                  ),
                ],
              ),
              if (latest.isNotEmpty) ...[
                const SizedBox(height: 10),
                for (final msg in latest.take(2))
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '${msg.senderName} — ${msg.title}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onTertiaryContainer.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
