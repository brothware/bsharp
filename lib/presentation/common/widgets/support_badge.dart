import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/support/tip_jar_sheet.dart';
import 'package:flutter/material.dart';

class SupportBadge extends StatelessWidget {
  const SupportBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => showTipJarSheet(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Opacity(
          opacity: 0.6,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.coffee_outlined,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                t.support.badge,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
