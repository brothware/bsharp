import 'package:flutter/material.dart';

const _minTouchTargetDp = 48.0;
const _chevronIconSizeDp = 18.0;

class WearPeriodSelector extends StatelessWidget {
  const WearPeriodSelector({
    required this.label,
    required this.onPrevious,
    required this.onNext,
    this.subLabel,
    super.key,
  });

  final String label;
  final String? subLabel;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: _minTouchTargetDp,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                if (subLabel != null)
                  Text(
                    subLabel!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            child: _WearPeriodChevron(
              icon: Icons.chevron_left,
              onTap: onPrevious,
            ),
          ),
          Positioned(
            right: 0,
            child: _WearPeriodChevron(
              icon: Icons.chevron_right,
              onTap: onNext,
            ),
          ),
        ],
      ),
    );
  }
}

class _WearPeriodChevron extends StatelessWidget {
  const _WearPeriodChevron({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: _minTouchTargetDp,
        height: _minTouchTargetDp,
        child: Center(
          child: Icon(
            icon,
            size: _chevronIconSizeDp,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
