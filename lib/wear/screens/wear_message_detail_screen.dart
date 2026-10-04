import 'dart:async';

import 'package:bsharp/app/data_provider_registry.dart';
import 'package:bsharp/app/locale_provider.dart';
import 'package:bsharp/app/translation_provider.dart';
import 'package:bsharp/domain/entities/poczta.dart';
import 'package:bsharp/domain/message_utils.dart';
import 'package:bsharp/domain/school_data_provider.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/wear/widgets/wear_fitted_text.dart';
import 'package:bsharp/wear/widgets/wear_scaffold.dart';
import 'package:bsharp/wear/widgets/wear_swipe_dismiss.dart';
import 'package:bsharp/wear/widgets/wear_translate_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WearMessageDetailScreen extends ConsumerStatefulWidget {
  const WearMessageDetailScreen({required this.message, super.key});

  final PocztaMessage message;

  @override
  ConsumerState<WearMessageDetailScreen> createState() =>
      _WearMessageDetailScreenState();
}

class _WearMessageDetailScreenState
    extends ConsumerState<WearMessageDetailScreen> {
  String? _fullContent;
  var _loadingContent = true;
  var _loadFailed = false;
  String? _translatedTitle;
  String? _translatedContent;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    unawaited(_fetchFullContent());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchFullContent() async {
    final dataProvider = ref.read(activeDataProviderProvider);
    final Map<String, dynamic>? data;
    try {
      data = await dataProvider.readMessage(widget.message.id);
    } on MessagingException catch (error, stackTrace) {
      debugPrint(
        'WearMessageDetailScreen: reading failed: $error\n$stackTrace',
      );
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
    setState(() {
      _fullContent = content;
      _loadingContent = false;
      _loadFailed = content == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = widget.message;
    final rawContent = _fullContent;
    final displayTitle = _translatedTitle ?? message.title;
    final displayContent =
        _translatedContent ??
        (rawContent != null ? stripHtml(rawContent) : null);

    return WearSwipeDismiss(
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: WearScaffold(
          scrollController: _scrollController,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: WearFittedText(
                      message.senderName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      formatMessageDateFull(message.sendTime),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  WearFittedText(
                    displayTitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                  ),
                  Divider(height: 8, color: theme.colorScheme.outlineVariant),
                  if (_loadingContent)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  else if (_loadFailed)
                    Text(
                      t.messages.readFailed,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  if (!_loadingContent && displayContent != null)
                    Text(displayContent, style: theme.textTheme.bodySmall),
                  if (message.files != null && message.files!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${t.messages.attachments} '
                        '(${message.files!.length})',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  if (rawContent != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: WearTranslateButton(
                        sourceText: stripHtml(rawContent),
                        onTranslated: _handleContentTranslation,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleContentTranslation(String? translated) async {
    if (translated == null) {
      setState(() {
        _translatedTitle = null;
        _translatedContent = null;
      });
      return;
    }

    setState(() => _translatedContent = translated);

    final service = ref.read(translationServiceProvider);
    final locale = ref.read(localeProvider).languageCode;
    final result = await service.translate(
      text: widget.message.title,
      targetLang: locale,
      sourceLang: ref.read(contentLanguageProvider),
    );
    if (!mounted) return;

    result.when(
      success: (title) => setState(() => _translatedTitle = title),
      failure: (_) {},
    );
  }
}
