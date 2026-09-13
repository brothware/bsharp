import 'package:flutter/material.dart';

class WearPinnedHeader extends StatelessWidget {
  const WearPinnedHeader({required this.child, this.minHeight = 32, super.key});

  final Widget child;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: child,
      ),
    );
  }
}
