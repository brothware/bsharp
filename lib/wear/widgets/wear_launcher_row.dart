import 'package:bsharp/wear/widgets/wear_fitted_text.dart';
import 'package:bsharp/wear/widgets/wear_list_item.dart';
import 'package:flutter/material.dart';

class WearLauncherRow extends StatelessWidget {
  const WearLauncherRow({
    required this.icon,
    required this.title,
    required this.summary,
    required this.onTap,
    this.scrollController,
    this.measureKey,
    super.key,
  });

  final IconData icon;
  final String title;
  final String summary;
  final VoidCallback onTap;
  final ScrollController? scrollController;
  final Key? measureKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final row = Material(
      key: measureKey,
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    WearFittedText(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                    ),
                    WearFittedText(
                      summary,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return WearListItem(scrollController: scrollController, child: row);
  }
}
