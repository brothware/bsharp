import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WearSwipeDismiss extends StatefulWidget {
  const WearSwipeDismiss({required this.child, super.key});

  final Widget child;

  @override
  State<WearSwipeDismiss> createState() => _WearSwipeDismissState();
}

class _WearSwipeDismissState extends State<WearSwipeDismiss>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _dragOffset = 0;

  static const _dismissThreshold = 60.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (details.primaryDelta == null) return;
    setState(() {
      _dragOffset = (_dragOffset + details.primaryDelta!).clamp(
        0.0,
        double.infinity,
      );
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_dragOffset.abs() >= _dismissThreshold) {
      unawaited(HapticFeedback.lightImpact());
      Navigator.of(context).pop();
    } else {
      setState(() => _dragOffset = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_dragOffset.abs() / _dismissThreshold).clamp(0.0, 1.0);

    return GestureDetector(
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Stack(
        children: [
          Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: Opacity(
              opacity: 1.0 - (progress * 0.3),
              child: widget.child,
            ),
          ),
          if (progress > 0)
            Positioned(
              left: 4,
              top: 0,
              bottom: 0,
              child: Center(
                child: Opacity(
                  opacity: progress,
                  child: Icon(
                    Icons.arrow_back,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
