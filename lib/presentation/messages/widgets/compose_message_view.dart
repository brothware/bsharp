import 'dart:async';

import 'package:bsharp/app/data_provider_registry.dart';
import 'package:bsharp/app/translation_provider.dart';
import 'package:bsharp/domain/entities/poczta.dart';
import 'package:bsharp/domain/translation_utils.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/messages/widgets/rich_text_editing_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ComposeMessageView extends ConsumerStatefulWidget {
  const ComposeMessageView({super.key, this.replyTo, this.prefilledRecipient});

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
  var _isSearching = false;
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
    final receivers = await dataProvider.searchReceivers(query);
    if (!mounted) return;

    setState(() {
      _searchResults = receivers;
      _isSearching = true;
    });
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.replyTo != null ? t.messages.reply : t.messages.newMessage,
        ),
        actions: [
          TextButton.icon(
            onPressed: _canSend ? () => _send(context) : null,
            icon: const Icon(Icons.send),
            label: Text(t.messages.send),
          ),
        ],
      ),
      body: Column(
        children: [
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
              ],
            ),
          ),
          _FormattingToolbar(
            controller: _contentController,
            onTranslateToPolish: ref.watch(isTranslationAvailableProvider)
                ? () => _translateToPolish(ref)
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
      _selectedRecipients.isNotEmpty &&
      _titleController.text.isNotEmpty &&
      _contentController.text.isNotEmpty;

  Future<void> _translateToPolish(WidgetRef ref) async {
    final text = _contentController.text;
    if (text.isEmpty) return;
    final service = ref.read(translationServiceProvider);
    final result = await service.translate(text: text, targetLang: 'pl');
    if (!mounted) return;
    result.when(
      success: (translated) => _contentController.text = translated,
      failure: (_) {},
    );
  }

  void _send(BuildContext context) {
    Navigator.of(context).pop({
      'title': _titleController.text,
      'content': _contentController.toHtml(),
      'recipientIds': _selectedRecipients.map((r) => r.recipientId).toList(),
      if (widget.replyTo != null) 'previousMessageId': widget.replyTo!.id,
    });
  }
}

class _FormattingToolbar extends StatelessWidget {
  const _FormattingToolbar({
    required this.controller,
    this.onTranslateToPolish,
  });

  final RichTextEditingController controller;
  final VoidCallback? onTranslateToPolish;

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
            if (onTranslateToPolish != null) ...[
              const Spacer(),
              _ToolbarButton(
                icon: Icons.translate,
                tooltip: t.translation.translateToPolish,
                onPressed: onTranslateToPolish!,
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
