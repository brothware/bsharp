import 'package:bsharp/app/locale_provider.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:bsharp/wear/widgets/wear_screen_layout.dart';
import 'package:bsharp/wear/widgets/wear_swipe_dismiss.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WearLanguageScreen extends ConsumerWidget {
  const WearLanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shape = ref.watch(wearScreenShapeProvider).requireValue;
    final currentLocale = ref.watch(localeProvider);
    final isSystem = ref.read(localeProvider.notifier).isSystemLocale;
    final theme = Theme.of(context);

    return WearSwipeDismiss(
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: WearScreenLayout(
          child: Column(
            children: [
              Icon(Icons.language, size: 20, color: theme.colorScheme.primary),
              const SizedBox(height: 2),
              Text(
                t.settings.language,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.only(bottom: wearListBottomInset(shape)),
                  itemCount: AppLocale.values.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _LanguageItem(
                        label: t.settings.languageSystem,
                        isSelected: isSystem,
                        onTap: () {
                          ref.read(localeProvider.notifier).resetToSystem();
                          Navigator.of(context).pop();
                        },
                      );
                    }
                    final locale = AppLocale.values[index - 1];
                    final flutterLocale = locale.flutterLocale;
                    final isSelected =
                        !isSystem &&
                        currentLocale.languageCode ==
                            flutterLocale.languageCode;

                    return _LanguageItem(
                      label: localeDisplayName(flutterLocale),
                      isSelected: isSelected,
                      onTap: () {
                        ref
                            .read(localeProvider.notifier)
                            .setLocale(flutterLocale);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageItem extends StatelessWidget {
  const _LanguageItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : null,
                  color: isSelected ? theme.colorScheme.primary : null,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check, size: 16, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }
}
