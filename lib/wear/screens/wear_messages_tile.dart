import 'package:bsharp/app/providers/messages_providers.dart';
import 'package:bsharp/domain/entities/poczta.dart';
import 'package:bsharp/domain/message_utils.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/wear/screens/wear_message_detail_screen.dart';
import 'package:bsharp/wear/screens/wear_messages_list_screen.dart';
import 'package:bsharp/wear/widgets/wear_tile_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _wearMessagesTileLimit = 4;

class WearMessagesTile extends ConsumerWidget {
  const WearMessagesTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inbox = ref.watch(inboxProvider);
    final unread = ref.watch(unreadCountProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        WearTileHeader(
          icon: Icons.mail_outline,
          title: t.nav.messages,
          trailing: unread > 0
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$unread',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onError,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : null,
        ),
        if (inbox.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.mail_outline,
                    size: 28,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t.messages.noMessages,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount:
                  inbox.take(_wearMessagesTileLimit).length +
                  (inbox.length > _wearMessagesTileLimit ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= inbox.take(_wearMessagesTileLimit).length) {
                  return _WearSeeAllRow(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const WearMessagesListScreen(),
                      ),
                    ),
                  );
                }
                final msg = inbox[index];
                return WearMessageItem(
                  message: msg,
                  onTap: () => _openDetail(context, msg),
                );
              },
            ),
          ),
      ],
    );
  }

  void _openDetail(BuildContext context, PocztaMessage message) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WearMessageDetailScreen(message: message),
      ),
    );
  }
}

class _WearSeeAllRow extends StatelessWidget {
  const _WearSeeAllRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(minHeight: 32),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Icon(
          Icons.more_horiz,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class WearMessageItem extends StatelessWidget {
  const WearMessageItem({
    required this.message,
    required this.onTap,
    super.key,
  });

  final PocztaMessage message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: !message.isRead
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
              : null,
        ),
        child: Row(
          children: [
            if (!message.isRead)
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary,
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.senderName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: message.isRead
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    message.title,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              formatMessageDate(message.sendTime),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
