import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WearVerticalOverscrollPager extends StatefulWidget {
  const WearVerticalOverscrollPager({
    required this.child,
    required this.onPrevious,
    required this.onNext,
    this.threshold = 60.0,
    super.key,
  });

  final Widget child;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final double threshold;

  @override
  State<WearVerticalOverscrollPager> createState() =>
      _WearVerticalOverscrollPagerState();
}

class _WearVerticalOverscrollPagerState
    extends State<WearVerticalOverscrollPager> {
  double _topAccumulated = 0;
  double _bottomAccumulated = 0;

  bool _handleScrollNotification(ScrollNotification notification) {
    switch (notification) {
      case OverscrollNotification(:final overscroll) when overscroll < 0:
        _topAccumulated += overscroll.abs();
      case OverscrollNotification(:final overscroll) when overscroll > 0:
        _bottomAccumulated += overscroll;
      case ScrollEndNotification():
        if (_topAccumulated >= widget.threshold) {
          unawaited(HapticFeedback.lightImpact());
          widget.onPrevious();
        } else if (_bottomAccumulated >= widget.threshold) {
          unawaited(HapticFeedback.lightImpact());
          widget.onNext();
        }
        _topAccumulated = 0;
        _bottomAccumulated = 0;
      default:
        break;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: widget.child,
    );
  }
}
