import 'package:bsharp/wear/widgets/wear_scaffold.dart';
import 'package:flutter/material.dart';

class WearTileHeader extends StatelessWidget {
  const WearTileHeader({
    required this.icon,
    required this.title,
    this.trailing,
    super.key,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final display = WearDisplayScope.of(context);

    if (display.isRound) {
      return _buildRound(context);
    }
    return _buildFlat(context);
  }

  Widget _buildFlat(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildRound(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleSmall?.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.bold,
    );

    return ColoredBox(
      color: theme.colorScheme.surface,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(height: 2),
            Text(title, style: titleStyle, overflow: TextOverflow.ellipsis),
            if (trailing case final trailing?) Center(child: trailing),
          ],
        ),
      ),
    );
  }
}
