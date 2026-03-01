import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/domain/entities/poczta.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/messages/providers/messages_providers.dart';
import 'package:bsharp/presentation/messages/widgets/compose_message_view.dart';
import 'package:bsharp/presentation/messages/widgets/message_detail_view.dart';
import 'package:bsharp/presentation/messages/widgets/message_tile.dart';

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(t.messages.title)),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            TabBar(
              tabs: [
                Tab(text: t.messages.inbox),
                Tab(text: t.messages.sent),
                Tab(text: t.messages.trash),
              ],
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor:
                  Theme.of(context).colorScheme.onSurfaceVariant,
              indicatorSize: TabBarIndicatorSize.label,
              onTap: (index) {
                final folder = MessageFolder.values[index];
                ref.read(selectedFolderProvider.notifier).state = folder;
              },
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _MessageList(folder: MessageFolder.inbox),
                  _MessageList(folder: MessageFolder.sent),
                  _MessageList(folder: MessageFolder.trash),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageList extends ConsumerWidget {
  const _MessageList({required this.folder});

  final MessageFolder folder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = switch (folder) {
      MessageFolder.inbox => ref.watch(inboxProvider),
      MessageFolder.sent => ref.watch(sentProvider),
      MessageFolder.trash => ref.watch(trashProvider),
    };

    if (messages.isEmpty) {
      return _EmptyMessages(folder: folder);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(syncStatusProvider.notifier).sync(),
      child: Stack(
        children: [
          ListView.separated(
            itemCount: messages.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final message = messages[index];
              return MessageTile(
                message: message,
                showRestore: folder == MessageFolder.trash,
                suppressUnread: folder != MessageFolder.inbox,
                onTap: () => _openDetail(context, ref, message),
                onStar: () {},
                onDelete: () => _confirmDelete(context, message),
                onRestore: () {},
              );
            },
          ),
          if (folder == MessageFolder.inbox)
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: () => _openCompose(context),
                child: const Icon(Icons.edit),
              ),
            ),
        ],
      ),
    );
  }

  void _openDetail(
    BuildContext context,
    WidgetRef ref,
    PocztaMessage message,
  ) {
    if (folder == MessageFolder.inbox && !message.isRead) {
      _markAsRead(ref, message);
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MessageDetailView(
          message: message,
          onReply: folder == MessageFolder.inbox
              ? () => _openCompose(context, replyTo: message)
              : null,
          onDelete: () {
            Navigator.of(context).pop();
          },
          onToggleStar: () {},
        ),
      ),
    );
  }

  void _markAsRead(WidgetRef ref, PocztaMessage message) {
    final inbox = ref.read(inboxProvider);
    final updated = [
      for (final m in inbox)
        if (m.id == message.id) m.copyWith(isRead: true) else m,
    ];
    ref.read(inboxProvider.notifier).state = updated;

    final pocztaDs = ref.read(pocztaDataSourceProvider);
    pocztaDs?.readMessage(message.id);
  }

  void _openCompose(BuildContext context, {PocztaMessage? replyTo}) {
    Navigator.of(context).push(
      MaterialPageRoute<Map<String, dynamic>>(
        builder: (_) => ComposeMessageView(replyTo: replyTo),
      ),
    );
  }

  void _confirmDelete(BuildContext context, PocztaMessage message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t.messages.deleted(title: message.title)),
        action: SnackBarAction(
          label: t.common.undo,
          onPressed: () {},
        ),
      ),
    );
  }
}

class _EmptyMessages extends StatelessWidget {
  const _EmptyMessages({required this.folder});

  final MessageFolder folder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, text) = switch (folder) {
      MessageFolder.inbox => (
          Icons.inbox_outlined,
          t.messages.noMessages,
        ),
      MessageFolder.sent => (
          Icons.send_outlined,
          t.messages.noSent,
        ),
      MessageFolder.trash => (
          Icons.delete_outline,
          t.messages.trashEmpty,
        ),
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 80),
        Icon(
          icon,
          size: 64,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 16),
        Text(
          text,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          t.common.dataAfterSync,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
