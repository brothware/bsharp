import 'dart:async';

import 'package:flutter/material.dart';

/// How long the scroll pill lingers after the last scroll, matched to
/// `WearOsScrollbar` so the two never share the edge.
const _pillLingers = Duration(milliseconds: 1500);
const _fade = Duration(milliseconds: 300);

/// Hides what is pinned to the edge of the glass while the scroll pill is up.
class WearEdgeContentFade extends StatefulWidget {
  const WearEdgeContentFade({
    required this.controller,
    required this.child,
    super.key,
  });

  final ScrollController controller;
  final Widget child;

  @override
  State<WearEdgeContentFade> createState() => _WearEdgeContentFadeState();
}

class _WearEdgeContentFadeState extends State<WearEdgeContentFade> {
  bool _shown = true;
  Timer? _restore;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(WearEdgeContentFade oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onScroll);
      widget.controller.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _restore?.cancel();
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    _restore?.cancel();
    _restore = Timer(_pillLingers, () {
      if (mounted) setState(() => _shown = true);
    });
    if (_shown && mounted) setState(() => _shown = false);
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !_shown,
      child: AnimatedOpacity(
        opacity: _shown ? 1 : 0,
        duration: _fade,
        child: widget.child,
      ),
    );
  }
}
