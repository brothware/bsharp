import 'package:flutter/material.dart';
import 'package:bsharp/domain/entities/poczta.dart';
import 'package:bsharp/domain/message_utils.dart';

class MessageTile extends StatelessWidget {
  const MessageTile({
    super.key,
    required this.message,
    this.onTap,
    this.onStar,
    this.onDelete,
    this.onRestore,
    this.showRestore = false,
    this.suppressUnread = false,
  });

  final PocztaMessage message;
  final VoidCallback? onTap;
  final VoidCallback? onStar;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final bool showRestore;
  final bool suppressUnread;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = !suppressUnread && !message.isRead;

    return Dismissible(
      key: ValueKey(message.id),
      background: _SwipeBackground(
        color: Colors.orange,
        icon: message.isStarred ? Icons.star_border : Icons.star,
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _SwipeBackground(
        color: showRestore ? Colors.green : theme.colorScheme.error,
        icon: showRestore ? Icons.restore : Icons.delete_outline,
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onStar?.call();
        } else {
          if (showRestore) {
            onRestore?.call();
          } else {
            onDelete?.call();
          }
        }
        return false;
      },
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: isUnread
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          child: Text(
            message.senderName.isNotEmpty
                ? message.senderName[0].toUpperCase()
                : '?',
            style: TextStyle(
              color: isUnread
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        title: Text(
          message.senderName,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isUnread ? FontWeight.bold : null,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.title,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isUnread ? FontWeight.w600 : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (message.preview != null)
              Text(
                messagePreview(message.preview!),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatMessageDate(message.sendTime),
              style: theme.textTheme.labelSmall?.copyWith(
                color: isUnread
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.isStarred)
                  Icon(
                    Icons.star,
                    size: 16,
                    color: Colors.orange,
                  ),
                if (message.files != null && message.files!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.attach_file,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ],
        ),
        isThreeLine: message.preview != null,
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.color,
    required this.icon,
    required this.alignment,
  });

  final Color color;
  final IconData icon;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Icon(icon, color: Colors.white),
    );
  }
}
