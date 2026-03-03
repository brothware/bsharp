import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bsharp/domain/entities/poczta.dart';
import 'package:bsharp/domain/message_utils.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/common/widgets/translate_button.dart';
import 'package:bsharp/presentation/messages/providers/messages_providers.dart';

class MessageDetailView extends ConsumerStatefulWidget {
  const MessageDetailView({
    super.key,
    required this.message,
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
    _fetchFullContent();
  }

  Future<void> _fetchFullContent() async {
    final pocztaDs = ref.read(pocztaDataSourceProvider);
    if (pocztaDs == null || !pocztaDs.hasSession) {
      if (mounted) setState(() => _loadingContent = false);
      return;
    }

    final result = await pocztaDs.readMessage(widget.message.id);
    if (!mounted) return;

    result.when(
      success: (data) {
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
      },
      failure: (_) => setState(() => _loadingContent = false),
    );
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
              TranslateButton(
                sourceText: '${message.title}\n---\n$rawContent',
                isHtml: true,
                onTranslated: (translated) {
                  setState(() {
                    if (translated != null) {
                      final parts = translated.split('\n---\n');
                      _translatedTitle = parts.first;
                      _translatedContent = parts.length > 1
                          ? stripHtml(parts.sublist(1).join('\n---\n'))
                          : null;
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
            if ((_detailFiles ?? message.files) case final files?
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

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({required this.attachment});

  final PocztaAttachment attachment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: Icon(
          _fileIcon(attachment.name),
          color: theme.colorScheme.primary,
        ),
        title: Text(
          attachment.name,
          style: theme.textTheme.bodyMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: attachment.size != null
            ? Text(
                formatFileSize(attachment.size!),
                style: theme.textTheme.bodySmall,
              )
            : null,
        trailing: const Icon(Icons.download_outlined),
        onTap: () => launchUrl(
          Uri.parse(attachment.url),
          mode: LaunchMode.externalApplication,
        ),
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
