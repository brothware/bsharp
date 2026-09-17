import 'package:bsharp/wear/widgets/wear_edge_content_fade.dart';
import 'package:flutter/material.dart';

const _minTouchTargetDp = 48.0;
const _chevronIconSizeDp = 18.0;

/// Previous and next, pinned to the left and right of the glass.
///
/// They sit at the vertical middle, which on a round screen is the one place
/// the display is its full width, and outside the content inset so they hug
/// the bezel instead of crowding whatever the screen is showing.
class WearSideNavigation extends StatelessWidget {
  const WearSideNavigation({
    required this.onPrevious,
    required this.onNext,
    required this.scrollController,
    super.key,
  });

  final VoidCallback onPrevious;
  final VoidCallback onNext;

  /// The list these chevrons share the edge with. The scroll pill is drawn on
  /// that same edge, so the two take turns rather than overlapping.
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: WearEdgeContentFade(
        controller: scrollController,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _WearSideChevron(
              icon: Icons.chevron_left,
              alignment: Alignment.centerLeft,
              onTap: onPrevious,
            ),
            _WearSideChevron(
              icon: Icons.chevron_right,
              alignment: Alignment.centerRight,
              onTap: onNext,
            ),
          ],
        ),
      ),
    );
  }
}

class _WearSideChevron extends StatelessWidget {
  const _WearSideChevron({
    required this.icon,
    required this.alignment,
    required this.onTap,
  });

  final IconData icon;
  final Alignment alignment;
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
        // out at the rim of its target, clear of the content the screen is
        // showing rather than centred on top of it
        child: Align(
          alignment: alignment,
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
