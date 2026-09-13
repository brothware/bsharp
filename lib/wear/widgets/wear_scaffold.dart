import 'dart:math' as math;

import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:bsharp/wear/widgets/wear_edge_scrollbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const double _roundInsetFactor = (1 - 1 / 1.4142135623730951) / 2;
const _rectangularHorizontalFactor = 0.05;
const _rectangularVerticalFactor = 0.04;

class WearDisplayScope extends InheritedWidget {
  const WearDisplayScope({
    required this.display,
    required super.child,
    super.key,
  });

  final WearDisplay display;

  static WearDisplay of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<WearDisplayScope>();
    assert(scope != null, 'No WearDisplayScope found in context');
    return scope!.display;
  }

  @override
  bool updateShouldNotify(WearDisplayScope oldWidget) =>
      oldWidget.display.shape != display.shape ||
      oldWidget.display.sizeDp != display.sizeDp;
}

class WearScaffold extends ConsumerWidget {
  const WearScaffold({
    required this.child,
    this.scrollController,
    this.edgeContent,
    super.key,
  });

  final Widget child;
  final ScrollController? scrollController;
  final Widget? edgeContent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shape = ref.watch(wearScreenShapeProvider).requireValue;
    final sizeDp = MediaQuery.sizeOf(context);
    final display = WearDisplay(shape: shape, sizeDp: sizeDp);
    final theme = Theme.of(context);

    return WearDisplayScope(
      display: display,
      child: ColoredBox(
        color: theme.colorScheme.surface,
        child: _withEdgeScrollbar(
          Stack(
            children: [
              Padding(padding: _insetFor(display), child: child),
              ?edgeContent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _withEdgeScrollbar(Widget content) {
    final controller = scrollController;
    if (controller == null) return content;
    return WearEdgeScrollbar(controller: controller, child: content);
  }

  EdgeInsets _insetFor(WearDisplay display) {
    if (display.isRound) {
      final inset =
          math.min(display.sizeDp.width, display.sizeDp.height) *
          _roundInsetFactor;
      return EdgeInsets.all(inset);
    }
    return EdgeInsets.symmetric(
      horizontal: display.sizeDp.width * _rectangularHorizontalFactor,
      vertical: display.sizeDp.height * _rectangularVerticalFactor,
    );
  }
}
