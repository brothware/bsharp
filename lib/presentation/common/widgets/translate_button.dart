import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bsharp/app/locale_provider.dart';
import 'package:bsharp/app/translation_provider.dart';
import 'package:bsharp/l10n/strings.g.dart';

class TranslateButton extends ConsumerStatefulWidget {
  const TranslateButton({
    required this.sourceText,
    required this.onTranslated,
    this.isHtml = false,
    super.key,
  });

  final String sourceText;
  final void Function(String?) onTranslated;
  final bool isHtml;

  @override
  ConsumerState<TranslateButton> createState() => _TranslateButtonState();
}

class _TranslateButtonState extends ConsumerState<TranslateButton> {
  _TranslationState _state = _TranslationState.idle;
  String? _translatedText;

  @override
  Widget build(BuildContext context) {
    final available = ref.watch(isTranslationAvailableProvider);
    if (!available) return const SizedBox.shrink();

    return switch (_state) {
      _TranslationState.idle => TextButton.icon(
          onPressed: _translate,
          icon: const Icon(Icons.translate, size: 18),
          label: Text(t.translation.translate),
        ),
      _TranslationState.loading => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Text(
                t.translation.translating,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      _TranslationState.translated => TextButton.icon(
          onPressed: _showOriginal,
          icon: const Icon(Icons.translate, size: 18),
          label: Text(t.translation.showOriginal),
        ),
      _TranslationState.error => TextButton.icon(
          onPressed: _translate,
          icon: const Icon(Icons.error_outline, size: 18),
          label: Text(t.translation.translationFailed),
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
        _translatedText = translated;
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
