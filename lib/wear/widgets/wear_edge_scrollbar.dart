import 'package:bsharp/wear/wear_app.dart';
import 'package:flutter/material.dart';
import 'package:wear_os_scrollbar/wear_os_scrollbar.dart';

const double _edgeMarginDp = 2;
const double _trackSweepDegrees = 60;

class WearEdgeScrollbar extends StatelessWidget {
  const WearEdgeScrollbar({
    required this.controller,
    required this.child,
    super.key,
  });

  final ScrollController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WearOsScrollbar(
      controller: controller,
      indicatorColor: theme.colorScheme.primary,
      backgroundColor: wearTrackColor(theme.colorScheme),
      marginRight: _edgeMarginDp,
      totalAngle: _trackSweepDegrees,
      child: child,
    );
  }
}
