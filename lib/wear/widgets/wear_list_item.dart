import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:bsharp/wear/widgets/wear_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:wear_os_scrollbar/wear_os_scrollbar.dart';

/// A row in a wear list, drawn smaller the closer it sits to the top or
/// bottom of the viewport.
///
/// The glass is a circle, so a row near the edge has far less width to live in
/// than one in the middle. Shrinking it there is what lets the screen keep a
/// thin margin instead of insetting every screen to the largest rectangle that
/// fits the circle, which costs a third of the display.
/// How far a row shrinks once it reaches the very edge of the viewport, which
/// is what the margin in [kWearRoundInsetFactor] is chosen against.
const double _edgeScale = 0.8;

class WearListItem extends StatelessWidget {
  const WearListItem({
    required this.child,
    this.scrollController,
    super.key,
  });

  final Widget child;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final controller = scrollController;
    if (controller == null || !WearDisplayScope.of(context).isRound) {
      return child;
    }

    return WearOsExpressiveItem(
      scrollController: controller,
      minScale: _edgeScale,
      child: child,
    );
  }
}

/// Wraps every row a [ListView.builder] produces in a [WearListItem].
IndexedWidgetBuilder wearScaledItems(
  ScrollController controller,
  IndexedWidgetBuilder builder,
) {
  return (context, index) => WearListItem(
    scrollController: controller,
    child: builder(context, index),
  );
}

/// Wraps a fixed list of rows in [WearListItem]s.
List<Widget> wearScaledChildren(
  ScrollController controller,
  List<Widget> children,
) {
  return [
    for (final child in children)
      WearListItem(scrollController: controller, child: child),
  ];
}

/// Room above and below a wear list so its first and last rows can be brought
/// to the middle of the glass, where the screen is widest and the eye is.
///
/// Without it a list stops the moment its last row appears at the bottom
/// edge, which is the worst place on a round screen to have to read it.
EdgeInsets wearListPadding(WearDisplay display) {
  if (!display.isRound) return EdgeInsets.zero;

  final content = display.sizeDp.shortestSide * (1 - 2 * kWearRoundInsetFactor);
  return EdgeInsets.symmetric(vertical: content * _centringFraction);
}

/// Enough to bring a row of ordinary height to the middle, not so much that
/// the list opens on empty space.
const double _centringFraction = 0.3;
