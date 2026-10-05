import 'dart:async';

import 'package:bsharp/app/data_provider_registry.dart';
import 'package:bsharp/app/providers/messages_providers.dart';
import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/domain/entities/poczta.dart';
import 'package:bsharp/domain/message_utils.dart';
import 'package:bsharp/domain/school_data_provider.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/common/widgets/html_body.dart';
import 'package:bsharp/presentation/common/widgets/obscurable_fab.dart';
import 'package:bsharp/presentation/common/widgets/translate_button.dart';
import 'package:bsharp/presentation/messages/widgets/compose_message_view.dart';
import 'package:bsharp/presentation/messages/widgets/mail_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';

class MessageDetailView extends ConsumerStatefulWidget {
  const MessageDetailView({
    required this.message,
    super.key,
  });

  final PocztaMessage message;

  @override
  ConsumerState<MessageDetailView> createState() => _MessageDetailViewState();
}

class _MessageDetailViewState extends ConsumerState<MessageDetailView> {
  String? _fullContent;
  List<PocztaAttachment>? _detailFiles;
  var _loadingContent = true;
  var _loadFailed = false;
  String? _translatedTitle;
  String? _translatedContent;

  @override
  void initState() {
    super.initState();
    unawaited(_fetchFullContent());
  }

  void _retry() {
    setState(() {
      _loadingContent = true;
      _loadFailed = false;
    });
    unawaited(_fetchFullContent());
  }

  Future<void> _fetchFullContent() async {
    final dataProvider = ref.read(activeDataProviderProvider);
    final Map<String, dynamic>? data;
    try {
      data = await dataProvider.readMessage(widget.message.id);
    } on MessagingException catch (error, stackTrace) {
      debugPrint('MessageDetailView: reading failed: $error\n$stackTrace');
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingContent = false;
        _loadFailed = true;
      });
      return;
    }
    if (!mounted) return;

    if (data == null) {
      setState(() {
        _fullContent = widget.message.content;
        _loadingContent = false;
        _loadFailed = _fullContent == null;
      });
      return;
    }

    final content = data['content'] as String?;
    if (content == null) {
      debugPrint(
        'MessageDetailView: message ${widget.message.id} came without content',
      );
    }
    final filesRaw = data['files'] as List<dynamic>?;
    final files = filesRaw
        ?.whereType<Map<String, dynamic>>()
        .map(
          (f) => PocztaAttachment(
            name: (f['name'] ?? '') as String,
            url: (f['url'] ?? '') as String,
            size: int.tryParse('${f['size'] ?? ''}'),
          ),
        )
        .toList();
    if (files != null && files.isNotEmpty) {
      _updateFilesInProvider(files);
    }
    setState(() {
      _fullContent = content;
      _detailFiles = files;
      _loadingContent = false;
      _loadFailed = content == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final folder = ref.watch(selectedFolderProvider);
    final messages = switch (folder) {
      MessageFolder.inbox => ref.watch(inboxProvider),
      MessageFolder.sent => ref.watch(sentProvider),
      MessageFolder.trash => ref.watch(trashProvider),
    };
    final message =
        messages.where((m) => m.id == widget.message.id).firstOrNull ??
        widget.message;
    final rawContent = _fullContent;
    final displayTitle = _translatedTitle ?? message.title;
    final isInbox = _isInbox;

    final scrollable = SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, isInbox ? 96 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(displayTitle, style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  message.senderName.isNotEmpty
                      ? message.senderName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.senderName,
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      formatMessageDateFull(message.sendTime),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (rawContent != null)
            MultiTranslateButton(
              fields: [
                TranslationField(message.title),
                TranslationField(rawContent, isHtml: true),
              ],
              onTranslated: (translations) {
                setState(() {
                  if (translations != null) {
                    _translatedTitle = translations[0];
                    _translatedContent = translations[1];
                  } else {
                    _translatedTitle = null;
                    _translatedContent = null;
                  }
                });
              },
            ),
          const Divider(height: 24),
          if (_loadingContent)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_loadFailed)
            _ReadFailure(onRetry: _retry)
          else if (_translatedContent case final translated?)
            HtmlBody(translated)
          else if (rawContent != null)
            HtmlBody(rawContent),
          if (_detailFiles ?? message.files case final files?
              when files.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(t.messages.attachments, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final file in files) _AttachmentTile(attachment: file),
          ],
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(t.messages.messageLabel),
        actions: [
          IconButton(
            icon: Icon(
              message.isStarred ? Icons.star : Icons.star_border,
              color: message.isStarred ? Colors.orange : null,
            ),
            onPressed: _toggleStar,
            tooltip: message.isStarred ? t.messages.unstar : t.messages.star,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _deleteAndPop(context),
            tooltip: t.messages.deleteTooltip,
          ),
        ],
      ),
      body: isInbox
          ? ObscurableFab(
              scrollable: scrollable,
              fab: FloatingActionButton.extended(
                onPressed: () =>
                    composeAndSend(context, ref, replyTo: widget.message),
                icon: const Icon(Icons.reply),
                label: Text(t.messages.reply),
              ),
            )
          : scrollable,
    );
  }

  bool get _isInbox => ref.read(selectedFolderProvider) == MessageFolder.inbox;

  List<PocztaMessage> _readFolder() {
    final folder = ref.read(selectedFolderProvider);
    return switch (folder) {
      MessageFolder.inbox => ref.read(inboxProvider),
      MessageFolder.sent => ref.read(sentProvider),
      MessageFolder.trash => ref.read(trashProvider),
    };
  }

  void _writeFolder(List<PocztaMessage> value) {
    final folder = ref.read(selectedFolderProvider);
    switch (folder) {
      case MessageFolder.inbox:
        ref.read(inboxProvider.notifier).value = value;
      case MessageFolder.sent:
        ref.read(sentProvider.notifier).value = value;
      case MessageFolder.trash:
        ref.read(trashProvider.notifier).value = value;
    }
  }

  void _toggleStar() {
    final message = widget.message;
    final messages = _readFolder();
    _writeFolder([
      for (final m in messages)
        if (m.id == message.id) m.copyWith(isStarred: !m.isStarred) else m,
    ]);
    final dataProvider = ref.read(activeDataProviderProvider);
    unawaited(
      runMailAction(
        messenger: ScaffoldMessenger.of(context),
        failureText: t.messages.actionFailed,
        action: () => dataProvider.toggleStar(message.id),
      ),
    );
  }

  void _deleteAndPop(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    context.pop();
    final message = widget.message;
    final folder = ref.read(selectedFolderProvider);
    final messages = _readFolder();
    _writeFolder(messages.where((m) => m.id != message.id).toList());

    final dataProvider = ref.read(activeDataProviderProvider);
    final syncNotifier = ref.read(syncStatusProvider.notifier);

    final isTrash = folder == MessageFolder.trash;
    unawaited(
      runMailAction(
        messenger: messenger,
        failureText: t.messages.actionFailed,
        action: () => isTrash
            ? dataProvider.restoreMessage(message.id)
            : dataProvider.deleteMessage(message.id),
      ).then((_) => syncNotifier.syncMessages()),
    );
  }

  void _updateFilesInProvider(List<PocztaAttachment> files) {
    final message = widget.message;
    final messages = _readFolder();
    _writeFolder([
      for (final m in messages)
        if (m.id == message.id) m.copyWith(files: files) else m,
    ]);
  }
}

class _ReadFailure extends StatelessWidget {
  const _ReadFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error),
          const SizedBox(height: 8),
          Text(
            t.messages.readFailed,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(t.common.retry),
          ),
        ],
      ),
    );
  }
}

class _AttachmentTile extends ConsumerStatefulWidget {
  const _AttachmentTile({required this.attachment});

  final PocztaAttachment attachment;

  @override
  ConsumerState<_AttachmentTile> createState() => _AttachmentTileState();
}

class _AttachmentTileState extends ConsumerState<_AttachmentTile> {
  var _downloading = false;

  Future<void> _download() async {
    setState(() => _downloading = true);
    try {
      final dataProvider = ref.read(activeDataProviderProvider);
      final path = await dataProvider.downloadAttachment(
        widget.attachment.url,
        widget.attachment.name,
      );
      if (!mounted) return;
      if (path != null) {
        await OpenFilex.open(path);
      } else {
        _showDownloadFailed();
      }
    } on MessagingException catch (error, stackTrace) {
      debugPrint('MessageDetailView: download failed: $error\n$stackTrace');
      _showDownloadFailed();
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  void _showDownloadFailed() {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.messages.downloadFailed)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: _downloading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                _fileIcon(widget.attachment.name),
                color: theme.colorScheme.primary,
              ),
        title: Text(
          widget.attachment.name,
          style: theme.textTheme.bodyMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: widget.attachment.size != null
            ? Text(
                formatFileSize(widget.attachment.size!),
                style: theme.textTheme.bodySmall,
              )
            : null,
        trailing: const Icon(Icons.download_outlined),
        onTap: _downloading ? null : _download,
      ),
    );
  }

  static IconData _fileIcon(String name) {
    final ext = name.split('.').last.toLowerCase();
    return switch (ext) {
      'pdf' => Icons.picture_as_pdf,
      'jpg' || 'jpeg' || 'png' || 'gif' => Icons.image_outlined,
      'doc' || 'docx' => Icons.description_outlined,
      'xls' || 'xlsx' => Icons.table_chart_outlined,
      _ => Icons.insert_drive_file_outlined,
    };
  }
}
