import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/domain/entities/poczta.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/messages/providers/messages_providers.dart';
import 'package:bsharp/presentation/messages/widgets/compose_message_view.dart';
import 'package:bsharp/presentation/messages/widgets/message_detail_view.dart';
import 'package:bsharp/presentation/messages/widgets/message_tile.dart';

const _loadMoreThreshold = 80.0;
const _inboxPageSize = 25;

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.messages.title),
        actions: [
          if (syncStatus == SyncStatus.syncing)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.sync),
              tooltip: t.settings.sync,
              onPressed: () =>
                  ref.read(syncStatusProvider.notifier).sync(),
            ),
        ],
      ),
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
                physics: const NeverScrollableScrollPhysics(),
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

class _MessageList extends ConsumerStatefulWidget {
  const _MessageList({required this.folder});

  final MessageFolder folder;

  @override
  ConsumerState<_MessageList> createState() => _MessageListState();
}

class _MessageListState extends ConsumerState<_MessageList> {
  final _removingIds = <int>{};
  bool _isLoadingMore = false;
  bool _overscrollTriggered = false;

  MessageFolder get folder => widget.folder;

  StateProvider<List<PocztaMessage>> get _folderProvider => switch (folder) {
    MessageFolder.inbox => inboxProvider,
    MessageFolder.sent => sentProvider,
    MessageFolder.trash => trashProvider,
  };

  void _toggleStar(PocztaMessage message) {
    final provider = _folderProvider;
    final messages = ref.read(provider);
    ref.read(provider.notifier).state = [
      for (final m in messages)
        if (m.id == message.id) m.copyWith(isStarred: !m.isStarred) else m,
    ];

    ref.read(pocztaDataSourceProvider)?.toggleStar(message.id);
  }

  void _removeMessage(PocztaMessage message) {
    if (_removingIds.contains(message.id)) return;
    setState(() => _removingIds.add(message.id));
  }

  void _completeRemoval(PocztaMessage message) {
    if (!mounted) return;
    setState(() => _removingIds.remove(message.id));

    final notifier = ref.read(_folderProvider.notifier);
    final messages = notifier.state;
    final index = messages.indexWhere((m) => m.id == message.id);
    notifier.state = messages.where((m) => m.id != message.id).toList();

    final pocztaDs = ref.read(pocztaDataSourceProvider);
    final syncNotifier = ref.read(syncStatusProvider.notifier);

    if (folder == MessageFolder.trash) {
      pocztaDs?.restoreMessage(message.id).then((_) {
        if (mounted) syncNotifier.syncMessages();
      });
      return;
    }

    pocztaDs?.deleteMessage(message.id).then((_) {
      if (mounted) syncNotifier.syncMessages();
    });

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
        SnackBar(
          content: Text(t.messages.deleted(title: message.title)),
          persist: false,
          action: SnackBarAction(
            label: t.common.undo,
            onPressed: () {
              final current = notifier.state;
              final restored = List<PocztaMessage>.of(current);
              restored.insert(index.clamp(0, restored.length), message);
              notifier.state = restored;

              pocztaDs?.restoreMessage(message.id).then((_) {
                syncNotifier.syncMessages();
              });
            },
          ),
        ),
      );
  }

  Future<void> _loadMoreInbox() async {
    setState(() => _isLoadingMore = true);
    final pocztaDs = ref.read(pocztaDataSourceProvider);
    final currentInbox = ref.read(inboxProvider);
    final result = await pocztaDs?.getInbox(skip: currentInbox.length);
    if (!mounted) return;
    result?.when(
      success: (data) {
        final newMessages = parsePocztaMessages(data);
        if (newMessages.length < _inboxPageSize) {
          ref.read(inboxHasMoreProvider.notifier).state = false;
        }
        ref.read(inboxProvider.notifier).state = [
          ...currentInbox,
          ...newMessages,
        ];
      },
      failure: (_) {},
    );
    if (mounted) setState(() => _isLoadingMore = false);
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (folder != MessageFolder.inbox ||
        _isLoadingMore ||
        !ref.read(inboxHasMoreProvider)) {
      return false;
    }

    final metrics = notification.metrics;
    final overscroll = metrics.pixels - metrics.maxScrollExtent;

    if (overscroll > _loadMoreThreshold && !_overscrollTriggered) {
      _overscrollTriggered = true;
      _loadMoreInbox();
    } else if (overscroll <= 0) {
      _overscrollTriggered = false;
    }

    if (notification is ScrollEndNotification &&
        metrics.pixels >= metrics.maxScrollExtent) {
      _loadMoreInbox();
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final messages = switch (folder) {
      MessageFolder.inbox => ref.watch(inboxProvider),
      MessageFolder.sent => ref.watch(sentProvider),
      MessageFolder.trash => ref.watch(trashProvider),
    };

    if (messages.isEmpty) {
      return _EmptyMessages(folder: folder);
    }

    final isInbox = folder == MessageFolder.inbox;
    final hasMore = isInbox && ref.watch(inboxHasMoreProvider);
    final showLoadingItem = isInbox && _isLoadingMore;
    final itemCount = messages.length + (showLoadingItem ? 1 : 0);

    return RefreshIndicator(
      onRefresh: () => ref.read(syncStatusProvider.notifier).sync(),
      child: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: _onScrollNotification,
            child: ListView.separated(
              physics: isInbox && hasMore
                  ? const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    )
                  : null,
              itemCount: itemCount,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                if (index >= messages.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final message = messages[index];
                return AnimatedMessageRemoval(
                  key: ValueKey(message.id),
                  isRemoving: _removingIds.contains(message.id),
                  onRemoved: () => _completeRemoval(message),
                  child: MessageTile(
                    message: message,
                    showRestore: folder == MessageFolder.trash,
                    suppressUnread: folder != MessageFolder.inbox,
                    onTap: () => _openDetail(context, message),
                    onStar: () => _toggleStar(message),
                    onDelete: () => _removeMessage(message),
                    onRestore: () => _removeMessage(message),
                  ),
                );
              },
            ),
          ),
          if (isInbox)
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

  void _openDetail(BuildContext context, PocztaMessage message) {
    if (folder == MessageFolder.inbox && !message.isRead) {
      _markAsRead(message);
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
            _removeMessage(message);
          },
          onToggleStar: () => _toggleStar(message),
          onFilesLoaded: (files) {
            final provider = _folderProvider;
            final messages = ref.read(provider);
            ref.read(provider.notifier).state = [
              for (final m in messages)
                if (m.id == message.id) m.copyWith(files: files) else m,
            ];
          },
        ),
      ),
    );
  }

  void _markAsRead(PocztaMessage message) {
    final inbox = ref.read(inboxProvider);
    ref.read(inboxProvider.notifier).state = [
      for (final m in inbox)
        if (m.id == message.id) m.copyWith(isRead: true) else m,
    ];
  }

  void _openCompose(BuildContext context, {PocztaMessage? replyTo}) {
    Navigator.of(context).push(
      MaterialPageRoute<Map<String, dynamic>>(
        builder: (_) => ComposeMessageView(replyTo: replyTo),
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
