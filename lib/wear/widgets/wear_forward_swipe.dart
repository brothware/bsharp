import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WearForwardSwipe extends StatefulWidget {
  const WearForwardSwipe({
    required this.child,
    required this.onTriggered,
    super.key,
  });

  final Widget child;
  final VoidCallback onTriggered;

  @override
  State<WearForwardSwipe> createState() => _WearForwardSwipeState();
}

class _WearForwardSwipeState extends State<WearForwardSwipe> {
  double _dragOffset = 0;

  static const _threshold = 60.0;

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (details.primaryDelta == null) return;
    setState(() {
      _dragOffset =
          (_dragOffset + details.primaryDelta!).clamp(double.negativeInfinity, 0.0);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_dragOffset.abs() >= _threshold) {
      HapticFeedback.lightImpact();
      widget.onTriggered();
    }
    setState(() => _dragOffset = 0);
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_dragOffset.abs() / _threshold).clamp(0.0, 1.0);

    return GestureDetector(
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Stack(
        children: [
          Transform.translate(
            offset: Offset(_dragOffset * 0.3, 0),
            child: widget.child,
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
                    Icons.chevron_left,
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
