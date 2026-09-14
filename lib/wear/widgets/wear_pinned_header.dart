import 'package:bsharp/wear/widgets/wear_scaffold.dart';
import 'package:flutter/material.dart';

class WearPinnedHeader extends StatelessWidget {
  const WearPinnedHeader({required this.child, this.minHeight = 32, super.key});

  final Widget child;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    // Pinned to the top of the content box, which is where a round screen is
    // at its narrowest, and unlike the rows below it never scrolls away from
    // there. So it takes the inset the circle asks for at that height.
    final inset = wearRoundInsetFor(
      WearDisplayScope.of(context),
      top: 0,
      bottom: minHeight,
    );

    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: inset),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: child,
        ),
      ),
    );
  }
}
