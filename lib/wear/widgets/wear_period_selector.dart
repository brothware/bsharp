import 'package:bsharp/wear/widgets/wear_fitted_text.dart';
import 'package:flutter/material.dart';

/// The label of whatever period the screen is showing.
///
/// Moving between periods belongs to the side navigation, out at the edges of
/// the glass; this only has to say where you are.
class WearPeriodSelector extends StatelessWidget {
  const WearPeriodSelector({required this.label, this.subLabel, super.key});

  final String label;
  final String? subLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        WearFittedText(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
          maxLines: 2,
          textAlign: TextAlign.center,
        ),
        if (subLabel case final subLabel?)
          WearFittedText(
            subLabel,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}
