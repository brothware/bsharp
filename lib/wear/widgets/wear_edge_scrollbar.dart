import 'package:flutter/material.dart';
import 'package:wear_os_scrollbar/wear_os_scrollbar.dart';

const double _edgeMarginDp = 2;

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
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      marginRight: _edgeMarginDp,
      child: child,
    );
  }
}
