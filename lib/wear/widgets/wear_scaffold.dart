import 'dart:math' as math;

import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:bsharp/wear/widgets/wear_edge_scrollbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A thin margin, not the largest rectangle that fits the circle: that
/// rectangle is only 64% of the glass, and rows narrow themselves near the top
/// and bottom where the circle does.
const double kWearRoundInsetFactor = 0.052;
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
          kWearRoundInsetFactor;
      return EdgeInsets.all(inset);
    }
    return EdgeInsets.symmetric(
      horizontal: display.sizeDp.width * _rectangularHorizontalFactor,
      vertical: display.sizeDp.height * _rectangularVerticalFactor,
    );
  }
}

/// How much narrower than the content box a band has to be to stay inside a
/// round screen, given where it sits below the top of that box.
///
/// The content box keeps only a thin margin, so near the top and bottom it is
/// wider than the glass. Scrolling rows shrink themselves; anything pinned in
/// place asks here instead.
double wearRoundInsetFor(
  WearDisplay display, {
  required double top,
  required double bottom,
}) {
  if (!display.isRound) return 0;

  final side = display.sizeDp.shortestSide;
  final radius = side / 2;
  final margin = side * kWearRoundInsetFactor;
  final contentHalf = radius - margin;

  final furthest = math.max(
    (radius - (margin + top)).abs(),
    (radius - (margin + bottom)).abs(),
  );
  if (furthest >= radius) return contentHalf;

  final available = math.sqrt(radius * radius - furthest * furthest);
  return math.max(0, contentHalf - available);
}

/// The extra inset a fixed grid needs inside the content box.
///
/// A row of cells sits at fixed columns, so shrinking one does not move it
/// inward the way a list row narrows: a grid cannot follow the curve and has
/// to settle for the largest rectangle that fits the circle.
double wearRoundGridInset(WearDisplay display) {
  if (!display.isRound) return 0;

  const inscribedSquareFactor = (1 - 1 / 1.4142135623730951) / 2;
  return display.sizeDp.shortestSide *
      (inscribedSquareFactor - kWearRoundInsetFactor);
}
