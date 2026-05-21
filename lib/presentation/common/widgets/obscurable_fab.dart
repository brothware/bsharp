import 'package:flutter/material.dart';

const double _obscuredOpacity = 0.4;
const Duration _obscureAnimationDuration = Duration(milliseconds: 200);

class ObscurableFab extends StatefulWidget {
  const ObscurableFab({
    required this.scrollable,
    required this.fab,
    this.alignment = Alignment.bottomRight,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  final Widget scrollable;
  final Widget fab;
  final AlignmentGeometry alignment;
  final EdgeInsetsGeometry padding;

  @override
  State<ObscurableFab> createState() => _ObscurableFabState();
}

class _ObscurableFabState extends State<ObscurableFab> {
  bool _obscured = true;

  void _update(ScrollMetrics metrics) {
    if (metrics.axis != Axis.vertical) return;
    final obscured =
        metrics.maxScrollExtent > 0 && metrics.pixels < metrics.maxScrollExtent;
    if (obscured != _obscured) {
      setState(() => _obscured = obscured);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        NotificationListener<ScrollMetricsNotification>(
          onNotification: (n) {
            _update(n.metrics);
            return false;
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              _update(n.metrics);
              return false;
            },
            child: widget.scrollable,
          ),
        ),
        Positioned.fill(
          child: Padding(
            padding: widget.padding,
            child: Align(
              alignment: widget.alignment,
              child: AnimatedOpacity(
                opacity: _obscured ? _obscuredOpacity : 1.0,
                duration: _obscureAnimationDuration,
                child: widget.fab,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
