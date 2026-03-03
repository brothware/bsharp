import 'package:bsharp/domain/entities/poczta.dart';
import 'package:bsharp/domain/message_utils.dart';
import 'package:bsharp/presentation/common/responsive.dart';
import 'package:flutter/material.dart';

class AnimatedMessageRemoval extends StatefulWidget {
  const AnimatedMessageRemoval({
    super.key,
    required this.isRemoving,
    required this.onRemoved,
    required this.child,
  });

  final bool isRemoving;
  final VoidCallback onRemoved;
  final Widget child;

  @override
  State<AnimatedMessageRemoval> createState() => _AnimatedMessageRemovalState();
}

class _AnimatedMessageRemovalState extends State<AnimatedMessageRemoval>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _sizeFactor;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _sizeFactor = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _opacity = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onRemoved();
      }
    });
  }

  @override
  void didUpdateWidget(AnimatedMessageRemoval oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRemoving && !oldWidget.isRemoving) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _sizeFactor,
      axisAlignment: -1,
      child: FadeTransition(opacity: _opacity, child: widget.child),
    );
  }
}

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
    final isWide = screenSizeOf(context) != ScreenSize.phone;

    final tile = ListTile(
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
              if (message.files != null && message.files!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.attach_file,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              if (isWide) ...[
                _ActionIcon(
                  onPressed: onStar,
                  icon: message.isStarred ? Icons.star : Icons.star_border,
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                if (showRestore)
                  _ActionIcon(
                    onPressed: onRestore,
                    icon: Icons.restore,
                    color: Colors.green,
                  )
                else
                  _ActionIcon(
                    onPressed: onDelete,
                    icon: Icons.delete_outline,
                    color: theme.colorScheme.error,
                  ),
              ] else if (message.isStarred)
                const Icon(Icons.star, size: 16, color: Colors.orange),
            ],
          ),
        ],
      ),
      isThreeLine: message.preview != null,
    );

    if (isWide) return tile;

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
      child: tile,
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.icon, required this.color, this.onPressed});

  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Icon(icon, size: 20, color: color),
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
