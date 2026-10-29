import 'package:bsharp/app/locale_provider.dart';
import 'package:bsharp/app/translation_provider.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _minTouchTargetDp = 48.0;

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
      _TranslationState.idle => _WearTranslateLink(
        icon: Icons.translate,
        label: t.translation.translate,
        color: theme.colorScheme.primary,
        onTap: _translate,
      ),
      _TranslationState.loading => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _minTouchTargetDp),
        child: Row(
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
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      _TranslationState.translated => _WearTranslateLink(
        icon: Icons.translate,
        label: t.translation.showOriginal,
        color: theme.colorScheme.primary,
        onTap: _showOriginal,
      ),
      _TranslationState.error => _WearTranslateLink(
        icon: Icons.error_outline,
        label: t.translation.translationFailed,
        color: theme.colorScheme.error,
        onTap: _translate,
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
      sourceLang: ref.read(contentLanguageProvider),
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

/// A link on the watch is still a touch target, so it gets the full 48dp
/// (WO-V2) however small its text.
class _WearTranslateLink extends StatelessWidget {
  const _WearTranslateLink({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_minTouchTargetDp / 2),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: _minTouchTargetDp,
          minWidth: _minTouchTargetDp,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
