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
    super.key,
  });

  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _WearSideChevron(icon: Icons.chevron_left, onTap: onPrevious),
          _WearSideChevron(icon: Icons.chevron_right, onTap: onNext),
        ],
      ),
    );
  }
}

class _WearSideChevron extends StatelessWidget {
  const _WearSideChevron({required this.icon, required this.onTap});

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
