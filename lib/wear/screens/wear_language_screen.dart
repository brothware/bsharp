import 'dart:async';

import 'package:bsharp/app/locale_provider.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/wear/widgets/wear_scaffold.dart';
import 'package:bsharp/wear/widgets/wear_swipe_dismiss.dart';
import 'package:bsharp/wear/widgets/wear_tile_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WearLanguageScreen extends ConsumerStatefulWidget {
  const WearLanguageScreen({super.key});

  @override
  ConsumerState<WearLanguageScreen> createState() => _WearLanguageScreenState();
}

class _WearLanguageScreenState extends ConsumerState<WearLanguageScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(localeProvider);
    final isSystem = ref.read(localeProvider.notifier).isSystemLocale;
    final theme = Theme.of(context);

    return WearSwipeDismiss(
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: WearScaffold(
          scrollController: _scrollController,
          child: Column(
            children: [
              WearTileHeader(
                icon: Icons.language,
                title: t.settings.language,
              ),
              const SizedBox(height: 4),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.zero,
                  itemCount: AppLocale.values.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _LanguageItem(
                        label: t.settings.languageSystem,
                        isSelected: isSystem,
                        onTap: () {
                          unawaited(
                            ref.read(localeProvider.notifier).resetToSystem(),
                          );
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
                        unawaited(
                          ref
                              .read(localeProvider.notifier)
                              .setLocale(flutterLocale),
                        );
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
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
      ),
    );
  }
}
