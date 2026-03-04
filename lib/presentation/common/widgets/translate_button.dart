import 'package:bsharp/app/locale_provider.dart';
import 'package:bsharp/app/translation_provider.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  @override
  Widget build(BuildContext context) {
    final available = ref.watch(isTranslationAvailableProvider);
    if (!available) return const SizedBox.shrink();

    return _translateButtonUI(
      context,
      state: _state,
      onTranslate: _translate,
      onShowOriginal: _showOriginal,
    );
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

class TranslationField {
  const TranslationField(this.text, {this.isHtml = false});

  final String text;
  final bool isHtml;
}

class MultiTranslateButton extends ConsumerStatefulWidget {
  const MultiTranslateButton({
    required this.fields,
    required this.onTranslated,
    super.key,
  });

  final List<TranslationField> fields;
  final void Function(List<String>?) onTranslated;

  @override
  ConsumerState<MultiTranslateButton> createState() =>
      _MultiTranslateButtonState();
}

class _MultiTranslateButtonState extends ConsumerState<MultiTranslateButton> {
  _TranslationState _state = _TranslationState.idle;

  @override
  Widget build(BuildContext context) {
    return _translateButtonUI(
      context,
      state: _state,
      onTranslate: _translate,
      onShowOriginal: _showOriginal,
    );
  }

  Future<void> _translate() async {
    setState(() => _state = _TranslationState.loading);

    final service = ref.read(translationServiceProvider);
    final locale = ref.read(localeProvider).languageCode;

    final results = await Future.wait(
      widget.fields.map(
        (f) => service.translate(
          text: f.text,
          targetLang: locale,
          isHtml: f.isHtml,
        ),
      ),
    );

    if (!mounted) return;

    final translations = <String>[];
    for (final result in results) {
      final value = result.when(success: (v) => v, failure: (_) => null);
      if (value == null) {
        setState(() => _state = _TranslationState.error);
        return;
      }
      translations.add(value);
    }

    setState(() => _state = _TranslationState.translated);
    widget.onTranslated(translations);
  }

  void _showOriginal() {
    setState(() => _state = _TranslationState.idle);
    widget.onTranslated(null);
  }
}

enum _TranslationState { idle, loading, translated, error }

Widget _translateButtonUI(
  BuildContext context, {
  required _TranslationState state,
  required VoidCallback onTranslate,
  required VoidCallback onShowOriginal,
}) {
  return switch (state) {
    _TranslationState.idle => TextButton.icon(
      onPressed: onTranslate,
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
      onPressed: onShowOriginal,
      icon: const Icon(Icons.translate, size: 18),
      label: Text(t.translation.showOriginal),
    ),
    _TranslationState.error => TextButton.icon(
      onPressed: onTranslate,
      icon: const Icon(Icons.error_outline, size: 18),
      label: Text(t.translation.translationFailed),
    ),
  };
}
