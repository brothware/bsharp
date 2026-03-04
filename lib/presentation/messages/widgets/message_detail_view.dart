import 'dart:async';

import 'package:bsharp/app/data_provider_registry.dart';
import 'package:bsharp/domain/entities/poczta.dart';
import 'package:bsharp/domain/message_utils.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/common/widgets/translate_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';

class MessageDetailView extends ConsumerStatefulWidget {
  const MessageDetailView({
    required this.message,
    super.key,
    this.onReply,
    this.onDelete,
    this.onToggleStar,
    this.onFilesLoaded,
  });

  final PocztaMessage message;
  final VoidCallback? onReply;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleStar;
  final void Function(List<PocztaAttachment> files)? onFilesLoaded;

  @override
  ConsumerState<MessageDetailView> createState() => _MessageDetailViewState();
}

class _MessageDetailViewState extends ConsumerState<MessageDetailView> {
  String? _fullContent;
  List<PocztaAttachment>? _detailFiles;
  var _loadingContent = true;
  String? _translatedTitle;
  String? _translatedContent;

  @override
  void initState() {
    super.initState();
    unawaited(_fetchFullContent());
  }

  Future<void> _fetchFullContent() async {
    final dataProvider = ref.read(activeDataProviderProvider);
    final data = await dataProvider.readMessage(widget.message.id);
    if (!mounted) return;

    if (data == null) {
      setState(() => _loadingContent = false);
      return;
    }

    final content = data['content'] as String?;
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
      widget.onFilesLoaded?.call(files);
    }
    setState(() {
      _fullContent = content;
      _detailFiles = files;
      _loadingContent = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = widget.message;
    final rawContent = _fullContent ?? message.content;
    final displayTitle = _translatedTitle ?? message.title;
    final displayContent =
        _translatedContent ??
        (rawContent != null ? stripHtml(rawContent) : null);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.messages.messageLabel),
        actions: [
          if (widget.onToggleStar != null)
            IconButton(
              icon: Icon(
                message.isStarred ? Icons.star : Icons.star_border,
                color: message.isStarred ? Colors.orange : null,
              ),
              onPressed: widget.onToggleStar,
              tooltip: message.isStarred ? t.messages.unstar : t.messages.star,
            ),
          if (widget.onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: widget.onDelete,
              tooltip: t.messages.deleteTooltip,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
                  TranslationField(stripHtml(rawContent)),
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
            else if (displayContent != null)
              SelectableText(displayContent, style: theme.textTheme.bodyMedium),
            if (_detailFiles ?? message.files case final files?
                when files.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(t.messages.attachments, style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              for (final file in files) _AttachmentTile(attachment: file),
            ],
          ],
        ),
      ),
      floatingActionButton: widget.onReply != null
          ? FloatingActionButton.extended(
              onPressed: widget.onReply,
              icon: const Icon(Icons.reply),
              label: Text(t.messages.reply),
            )
          : null,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.messages.downloadFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
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
