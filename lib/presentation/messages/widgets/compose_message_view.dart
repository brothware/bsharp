import 'dart:async';

import 'package:bsharp/app/attachment_providers.dart';
import 'package:bsharp/app/data_provider_registry.dart';
import 'package:bsharp/app/locale_provider.dart';
import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/app/translation_provider.dart';
import 'package:bsharp/domain/entities/outgoing_attachment.dart';
import 'package:bsharp/domain/entities/poczta.dart';
import 'package:bsharp/domain/school_data_provider.dart';
import 'package:bsharp/domain/translation_utils.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/messages/attachments/attachment_picker.dart';
import 'package:bsharp/presentation/messages/widgets/attachment_widgets.dart';
import 'package:bsharp/presentation/messages/widgets/rich_text_editing_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> composeAndSend(
  BuildContext context,
  WidgetRef ref, {
  PocztaMessage? replyTo,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final syncNotifier = ref.read(syncStatusProvider.notifier);
  final isSent = await Navigator.of(context).push(
    MaterialPageRoute<bool>(
      builder: (_) => ComposeMessageView(replyTo: replyTo),
    ),
  );
  if (isSent != true) {
    return;
  }
  messenger.showSnackBar(SnackBar(content: Text(t.messages.messageSent)));
  unawaited(syncNotifier.syncMessages());
}

class ComposeMessageView extends ConsumerStatefulWidget {
  const ComposeMessageView({
    super.key,
    this.replyTo,
    this.prefilledRecipient,
  });

  final PocztaMessage? replyTo;
  final PocztaReceiver? prefilledRecipient;

  @override
  ConsumerState<ComposeMessageView> createState() => _ComposeMessageViewState();
}

class _ComposeMessageViewState extends ConsumerState<ComposeMessageView> {
  final _titleController = TextEditingController();
  final _contentController = RichTextEditingController();
  final _searchController = TextEditingController();
  final _selectedRecipients = <PocztaReceiver>[];
  var _searchResults = <PocztaReceiver>[];
  final _attachments = <OutgoingAttachment>[];
  var _isSearching = false;
  var _isSending = false;
  var _isTransferring = false;
  ({int index, int total})? _uploadProgress;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onFieldChanged);
    _contentController.addListener(_onFieldChanged);
    if (widget.replyTo != null) {
      _titleController.text = t.messages.replyPrefix(
        title: widget.replyTo!.title,
      );
      final sender = widget.replyTo!.senderName;
      if (sender.isNotEmpty) {
        _selectedRecipients.add(PocztaReceiver(id: 'user_reply', name: sender));
      }
    }
    if (widget.prefilledRecipient != null) {
      _selectedRecipients.add(widget.prefilledRecipient!);
    }
  }

  void _onFieldChanged() => setState(() {});

  @override
  void dispose() {
    _debounce?.cancel();
    _titleController.removeListener(_onFieldChanged);
    _contentController.removeListener(_onFieldChanged);
    _titleController.dispose();
    _contentController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.length < 2) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      unawaited(_performSearch(query));
    });
  }

  Future<void> _performSearch(String query) async {
    final dataProvider = ref.read(activeDataProviderProvider);
    final List<PocztaReceiver> receivers;
    try {
      receivers = await dataProvider.searchReceivers(query);
    } on MessagingException catch (error, stackTrace) {
      _reportSearchFailure(error, stackTrace);
      return;
    } on FormatException catch (error, stackTrace) {
      _reportSearchFailure(error, stackTrace);
      return;
    }
    if (!mounted) return;

    setState(() {
      _searchResults = receivers;
      _isSearching = true;
    });
  }

  void _reportSearchFailure(Object error, StackTrace stackTrace) {
    debugPrint('ComposeMessageView: search failed: $error\n$stackTrace');
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.messages.searchFailed)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: theme.colorScheme.outline.withValues(alpha: 0.3),
      ),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: theme.colorScheme.primary),
    );

    return PopScope(
      canPop: !_isSending,
      child: _buildScaffold(theme, fieldBorder, focusedBorder),
    );
  }

  Widget _buildScaffold(
    ThemeData theme,
    OutlineInputBorder fieldBorder,
    OutlineInputBorder focusedBorder,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.replyTo != null ? t.messages.reply : t.messages.newMessage,
        ),
        actions: [
          IconButton(
            onPressed: _isSending ? null : _pickAttachments,
            icon: const Icon(Icons.attach_file),
            tooltip: t.compose.attach,
          ),
          TextButton.icon(
            onPressed: _canSend ? _send : null,
            icon: const Icon(Icons.send),
            label: Text(t.messages.send),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isTransferring) _SendingProgress(upload: _uploadProgress),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_selectedRecipients.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final r in _selectedRecipients)
                        InputChip(
                          label: Text(r.name),
                          onDeleted: () => setState(() {
                            _selectedRecipients.remove(r);
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: t.messages.addRecipient,
                    border: fieldBorder,
                    enabledBorder: fieldBorder,
                    focusedBorder: focusedBorder,
                    prefixIcon: const Icon(Icons.person_add_outlined),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onChanged: _onSearchChanged,
                ),
                if (_isSearching && _searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final receiver = _searchResults[index];
                        return ListTile(
                          dense: true,
                          title: Text(receiver.name),
                          subtitle: receiver.role != null
                              ? Text(translateReceiverRole(receiver.role!))
                              : null,
                          onTap: () {
                            setState(() {
                              final existingIndex = _selectedRecipients
                                  .indexWhere(
                                    (r) =>
                                        r.id == receiver.id ||
                                        r.name == receiver.name,
                                  );
                              if (existingIndex >= 0) {
                                _selectedRecipients[existingIndex] = receiver;
                              } else {
                                _selectedRecipients.add(receiver);
                              }
                              _searchController.clear();
                              _isSearching = false;
                              _searchResults = [];
                            });
                          },
                        );
                      },
                    ),
                  ),
                if (_isSearching && _searchResults.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      t.messages.noResults,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: t.messages.subject,
                    border: fieldBorder,
                    enabledBorder: fieldBorder,
                    focusedBorder: focusedBorder,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (_attachments.isNotEmpty) ...[
                  AttachmentChips(
                    attachments: _attachments,
                    onRemove: _isSending
                        ? null
                        : (attachment) => setState(() {
                            _attachments.remove(attachment);
                          }),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          _FormattingToolbar(
            controller: _contentController,
            onTranslate: ref.watch(isTranslationAvailableProvider)
                ? () => _translateForRecipient(ref)
                : null,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: TextField(
                controller: _contentController,
                decoration: InputDecoration(
                  hintText: t.messages.content,
                  border: fieldBorder,
                  enabledBorder: fieldBorder,
                  focusedBorder: focusedBorder,
                  contentPadding: const EdgeInsets.all(16),
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool get _canSend =>
      !_isSending &&
      _selectedRecipients.isNotEmpty &&
      _titleController.text.isNotEmpty &&
      _contentController.text.isNotEmpty;

  Future<void> _translateForRecipient(WidgetRef ref) async {
    final text = _contentController.text;
    if (text.isEmpty) return;
    final service = ref.read(translationServiceProvider);
    final result = await service.translate(
      text: text,
      targetLang: ref.read(contentLanguageProvider),
      sourceLang: ref.read(localeProvider).languageCode,
    );
    if (!mounted) return;
    result.when(
      success: (translated) => _contentController.text = translated,
      failure: (_) {},
    );
  }

  void _showSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _pickAttachments() async {
    final picker = ref.read(attachmentPickerProvider);
    final source = await showAttachmentSourceSheet(
      context,
      canUseCamera: picker.canUseCamera,
    );
    if (source == null || !mounted) {
      return;
    }
    final List<OutgoingAttachment> picked;
    try {
      picked = await picker.pick(source);
    } on Exception catch (error, stackTrace) {
      debugPrint('ComposeMessageView: pick failed: $error\n$stackTrace');
      if (mounted) {
        _showSnackBar(t.compose.pickFailed);
      }
      return;
    }
    if (!mounted) {
      return;
    }
    final limit = attachmentSizeLimit(Localizations.localeOf(context));
    for (final attachment in picked.where((a) => a.isTooLarge)) {
      _showSnackBar(t.compose.tooLarge(name: attachment.name, limit: limit));
    }
    setState(() {
      _attachments.addAll(picked.where((a) => !a.isTooLarge));
    });
  }

  Future<void> _send() async {
    setState(() => _isSending = true);
    final bool isSent;
    try {
      isSent = await _sendWithAttachments(List.of(_attachments));
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
          _isTransferring = false;
          _uploadProgress = null;
        });
      }
    }
    if (isSent && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<bool> _sendWithAttachments(
    List<OutgoingAttachment> attachments,
  ) async {
    final dataProvider = ref.read(activeDataProviderProvider);
    if (attachments.isNotEmpty && !await _areSendable(attachments)) {
      return false;
    }
    if (!mounted) {
      return false;
    }
    setState(() => _isTransferring = true);
    if (attachments.isNotEmpty && !await _isMailboxReady(dataProvider)) {
      return false;
    }
    final sent = await _sendMessage(dataProvider);
    if (sent == null) {
      return false;
    }
    final messageId = sent.messageId;
    if (messageId == null) {
      if (attachments.isNotEmpty && mounted) {
        setState(() => _isTransferring = false);
        await showAttachmentsLostDialog(context);
      }
      return true;
    }
    var pending = attachments;
    while (pending.isNotEmpty && mounted) {
      final failed = await _uploadPending(dataProvider, messageId, pending);
      if (failed.isEmpty || !mounted) {
        break;
      }
      setState(() => _isTransferring = false);
      final shouldRetry = await showUploadFailureDialog(context, failed);
      pending = shouldRetry
          ? [for (final result in failed) result.attachment]
          : const [];
    }
    return true;
  }

  Future<bool> _areSendable(List<OutgoingAttachment> attachments) async {
    final problems = await ref
        .read(attachmentInspectorProvider)
        .problemsWith(attachments);
    if (problems.isEmpty) {
      return true;
    }
    if (mounted) {
      await showAttachmentProblemsDialog(context, problems);
    }
    return false;
  }

  Future<bool> _isMailboxReady(SchoolDataProvider dataProvider) async {
    try {
      await dataProvider.ensureMailSession();
      return true;
    } on Exception catch (error, stackTrace) {
      debugPrint(
        'ComposeMessageView: mailbox check failed: $error\n$stackTrace',
      );
      if (mounted) {
        _showSnackBar(t.compose.mailboxUnavailable);
      }
      return false;
    }
  }

  Future<({int? messageId})?> _sendMessage(
    SchoolDataProvider dataProvider,
  ) async {
    try {
      final messageId = await dataProvider.sendMessage(
        recipientIds: _selectedRecipients.map((r) => r.recipientId).toList(),
        title: _titleController.text,
        content: _contentController.toHtml(),
        previousMessageId: widget.replyTo?.id,
      );
      return (messageId: messageId);
    } on SentWithoutIdException catch (error, stackTrace) {
      debugPrint('ComposeMessageView: sent without an id: $error\n$stackTrace');
      return (messageId: null);
    } on Exception catch (error, stackTrace) {
      debugPrint('ComposeMessageView: send failed: $error\n$stackTrace');
      if (mounted) {
        _showSnackBar(t.messages.sendFailed);
      }
      return null;
    }
  }

  Future<List<AttachmentUploadResult>> _uploadPending(
    SchoolDataProvider dataProvider,
    int messageId,
    List<OutgoingAttachment> pending,
  ) async {
    setState(() {
      _isTransferring = true;
      _uploadProgress = (index: 0, total: pending.length);
    });
    try {
      final results = await dataProvider.uploadAttachments(
        messageId,
        pending,
        onUploading: (index) {
          if (mounted) {
            setState(
              () => _uploadProgress = (index: index, total: pending.length),
            );
          }
        },
      );
      return [
        for (final result in results)
          if (!result.isUploaded) result,
      ];
    } on MessagingException catch (error, stackTrace) {
      debugPrint('ComposeMessageView: uploads failed: $error\n$stackTrace');
      return [
        for (final attachment in pending)
          AttachmentUploadResult.failed(
            attachment,
            AttachmentUploadFailure.server,
          ),
      ];
    }
  }
}

class _SendingProgress extends StatelessWidget {
  const _SendingProgress({required this.upload});

  final ({int index, int total})? upload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final upload = this.upload;
    final label = upload == null
        ? t.compose.sending
        : t.compose.uploading(current: upload.index + 1, total: upload.total);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinearProgressIndicator(
          value: upload == null ? null : upload.index / upload.total,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(label, style: theme.textTheme.bodySmall),
        ),
      ],
    );
  }
}

class _FormattingToolbar extends StatelessWidget {
  const _FormattingToolbar({
    required this.controller,
    this.onTranslate,
  });

  final RichTextEditingController controller;
  final VoidCallback? onTranslate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = controller.activeFormats;
    return FocusScope(
      canRequestFocus: false,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
        ),
        child: Row(
          children: [
            _ToolbarButton(
              icon: Icons.format_bold,
              tooltip: t.messages.bold,
              isActive: active.contains(FormatType.bold),
              onPressed: () => controller.toggleFormat(FormatType.bold),
            ),
            _ToolbarButton(
              icon: Icons.format_italic,
              tooltip: t.messages.italic,
              isActive: active.contains(FormatType.italic),
              onPressed: () => controller.toggleFormat(FormatType.italic),
            ),
            _ToolbarButton(
              icon: Icons.format_underlined,
              tooltip: t.messages.underline,
              isActive: active.contains(FormatType.underline),
              onPressed: () => controller.toggleFormat(FormatType.underline),
            ),
            if (onTranslate != null) ...[
              const Spacer(),
              _ToolbarButton(
                icon: Icons.translate,
                tooltip: t.translation.translate,
                onPressed: onTranslate!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isActive = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      isSelected: isActive,
      style: isActive
          ? IconButton.styleFrom(
              backgroundColor: theme.colorScheme.primaryContainer,
            )
          : null,
    );
  }
}
