import 'package:bsharp/wear/wear_crown_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WearCrownScroll extends ConsumerStatefulWidget {
  const WearCrownScroll({
    required this.controller,
    required this.child,
    this.scrollSensitivity = 50.0,
    this.onBoundaryUp,
    this.onBoundaryDown,
    super.key,
  });

  final ScrollController controller;
  final Widget child;
  final double scrollSensitivity;
  final VoidCallback? onBoundaryUp;
  final VoidCallback? onBoundaryDown;

  @override
  ConsumerState<WearCrownScroll> createState() => _WearCrownScrollState();
}

class _WearCrownScrollState extends ConsumerState<WearCrownScroll> {
  @override
  void initState() {
    super.initState();
    ref.listenManual(wearCrownEventsProvider, _onCrownEvent);
  }

  void _onCrownEvent(AsyncValue<double>? previous, AsyncValue<double> next) {
    final delta = next.valueOrNull;
    if (delta == null) return;

    final controller = widget.controller;
    if (!controller.hasClients) return;

    if (controller is PageController) {
      _handlePageScroll(controller, delta);
    } else {
      _handleListScroll(controller, delta);
    }
  }

  void _handlePageScroll(PageController controller, double delta) {
    if (delta > 0) {
      controller.nextPage(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    } else if (delta < 0) {
      controller.previousPage(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleListScroll(ScrollController controller, double delta) {
    final pos = controller.position;
    if (delta < 0 && pos.pixels <= pos.minScrollExtent) {
      widget.onBoundaryUp?.call();
      return;
    }
    if (delta > 0 && pos.pixels >= pos.maxScrollExtent) {
      widget.onBoundaryDown?.call();
      return;
    }
    final target = (controller.offset + delta * widget.scrollSensitivity).clamp(
      pos.minScrollExtent,
      pos.maxScrollExtent,
    );
    controller.animateTo(
      target,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
