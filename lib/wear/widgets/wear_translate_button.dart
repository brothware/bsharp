import 'package:bsharp/app/locale_provider.dart';
import 'package:bsharp/app/translation_provider.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WearTranslateButton extends ConsumerStatefulWidget {
  const WearTranslateButton({
    required this.sourceText,
    required this.onTranslated,
    this.isHtml = false,
    super.key,
  });

  final String sourceText;
  final ValueChanged<String?> onTranslated;
  final bool isHtml;

  @override
  ConsumerState<WearTranslateButton> createState() =>
      _WearTranslateButtonState();
}

class _WearTranslateButtonState extends ConsumerState<WearTranslateButton> {
  _TranslationState _state = _TranslationState.idle;

  @override
  Widget build(BuildContext context) {
    final available = ref.watch(isTranslationAvailableProvider);
    if (!available) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return switch (_state) {
      _TranslationState.idle => GestureDetector(
        onTap: _translate,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.translate, size: 14, color: theme.colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              t.translation.translate,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 9,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
      _TranslationState.loading => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            t.translation.translating,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 9,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      _TranslationState.translated => GestureDetector(
        onTap: _showOriginal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.translate, size: 14, color: theme.colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              t.translation.showOriginal,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 9,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
      _TranslationState.error => GestureDetector(
        onTap: _translate,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 14, color: theme.colorScheme.error),
            const SizedBox(width: 4),
            Text(
              t.translation.translationFailed,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 9,
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    };
  }

  Future<void> _translate() async {
    setState(() => _state = _TranslationState.loading);

    final service = ref.read(translationServiceProvider);
    final locale = ref.read(localeProvider).languageCode;

    final result = await service.translate(
      text: widget.sourceText,
      targetLang: locale,
      isHtml: widget.isHtml,
    );

    if (!mounted) return;

    result.when(
      success: (translated) {
        setState(() => _state = _TranslationState.translated);
        widget.onTranslated(translated);
      },
      failure: (_) {
        setState(() => _state = _TranslationState.error);
      },
    );
  }

  void _showOriginal() {
    setState(() => _state = _TranslationState.idle);
    widget.onTranslated(null);
  }
}

enum _TranslationState { idle, loading, translated, error }
