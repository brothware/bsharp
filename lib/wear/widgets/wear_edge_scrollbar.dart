import 'package:bsharp/wear/wear_app.dart';
import 'package:flutter/material.dart';
import 'package:wear_os_scrollbar/wear_os_scrollbar.dart';

const double _edgeMarginDp = 2;
const double _trackSweepDegrees = 60;

class WearEdgeScrollbar extends StatefulWidget {
  const WearEdgeScrollbar({
    required this.controller,
    required this.child,
    super.key,
  });

  final ScrollController controller;
  final Widget child;

  @override
  State<WearEdgeScrollbar> createState() => _WearEdgeScrollbarState();
}

class _WearEdgeScrollbarState extends State<WearEdgeScrollbar> {
  final GlobalKey _childKey = GlobalKey();
  bool _hasContentDimensions = false;

  bool _onScrollMetrics(ScrollMetricsNotification notification) {
    if (!_hasContentDimensions && _controllerHasContentDimensions) {
      setState(() => _hasContentDimensions = true);
    }
    return false;
  }

  bool get _controllerHasContentDimensions =>
      widget.controller.hasClients &&
      widget.controller.position.hasContentDimensions;

  @override
  Widget build(BuildContext context) {
    final child = KeyedSubtree(key: _childKey, child: widget.child);
    if (!_hasContentDimensions) {
      return NotificationListener<ScrollMetricsNotification>(
        onNotification: _onScrollMetrics,
        child: child,
      );
    }

    final theme = Theme.of(context);
    return WearOsScrollbar(
      controller: widget.controller,
      indicatorColor: theme.colorScheme.primary,
      backgroundColor: wearTrackColor(theme.colorScheme),
      marginRight: _edgeMarginDp,
      totalAngle: _trackSweepDegrees,
      child: child,
    );
  }
}
