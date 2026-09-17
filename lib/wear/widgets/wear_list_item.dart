import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:bsharp/wear/widgets/wear_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A row in a wear list, painted smaller the closer it sits to the top or
/// bottom of the viewport.
///
/// The shrinking is a paint transform and never the row's extent. Tying the
/// extent to the scroll offset - which is what `WearOsExpressiveItem` does
/// with `Align(heightFactor:)` - makes a lazy list unable to settle: scrolling
/// up forces the sliver to lay out rows above the viewport and correct the
/// offset, the correction rescales every row, the new heights force another
/// correction, and the list oscillates with no input at all.
///
/// The glass is a circle, so a row near the edge has far less width to live in
/// than one in the middle. Shrinking it there is what lets the screen keep a
/// thin margin instead of insetting every screen to the largest rectangle that
/// fits the circle, which costs a third of the display.
/// How far a row shrinks once it reaches the very edge of the viewport, which
/// is what the margin in [kWearRoundInsetFactor] is chosen against.
const double _edgeScale = 0.8;

class WearListItem extends StatelessWidget {
  const WearListItem({
    required this.child,
    this.scrollController,
    super.key,
  });

  final Widget child;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final controller = scrollController;
    if (controller == null || !WearDisplayScope.of(context).isRound) {
      return child;
    }

    return _EdgeScaled(controller: controller, child: child);
  }
}

/// Paints its child smaller towards the ends of the viewport.
///
/// The scale is read and applied at paint time, when the row's position is
/// already settled, so it can never change what the row measured.
class _EdgeScaled extends SingleChildRenderObjectWidget {
  const _EdgeScaled({required this.controller, required super.child});

  final ScrollController controller;

  @override
  _RenderEdgeScaled createRenderObject(BuildContext context) =>
      _RenderEdgeScaled(controller);

  @override
  void updateRenderObject(BuildContext context, _RenderEdgeScaled render) {
    render.controller = controller;
  }
}

class _RenderEdgeScaled extends RenderProxyBox {
  _RenderEdgeScaled(this._controller) {
    _controller.addListener(markNeedsPaint);
  }

  ScrollController _controller;
  ScrollController get controller => _controller;

  set controller(ScrollController value) {
    if (value == _controller) return;
    _controller.removeListener(markNeedsPaint);
    _controller = value;
    _controller.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  @override
  void detach() {
    _controller.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _controller.addListener(markNeedsPaint);
  }

  /// Full size through the middle of the glass, shrinking to [_edgeScale] over
  /// the outer quarter at each end.
  ///
  /// Measured against the viewport this row is painted into rather than the
  /// controller: while a screen swaps one list for another the controller is
  /// briefly attached to both, and asking it for `position` then throws - in
  /// the middle of paint, which leaves the whole list drawing nothing.
  double get _scale {
    if (!hasSize) return 1;

    final RenderObject? viewport = RenderAbstractViewport.maybeOf(this);
    if (viewport is! RenderBox) return 1;
    if (!viewport.hasSize) return 1;

    final halfViewport = viewport.size.height / 2;
    if (halfViewport <= 0) return 1;

    final centre = localToGlobal(
      size.center(Offset.zero),
      ancestor: viewport,
    ).dy;
    final normalised = ((centre - halfViewport).abs() / halfViewport).clamp(
      0.0,
      1.0,
    );
    if (normalised <= 0.5) return 1;

    final intoEdge = (normalised - 0.5) / 0.5;
    return 1 - (1 - _edgeScale) * Curves.easeIn.transform(intoEdge);
  }

  Matrix4 _transformAt(double scale) {
    final centre = size.center(Offset.zero);
    return Matrix4.identity()
      ..translateByDouble(centre.dx, centre.dy, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1)
      ..translateByDouble(-centre.dx, -centre.dy, 0, 1);
  }

  // A row painted smaller has to be hit where it is drawn, not where it was
  // laid out, or a tap near the edge lands on the wrong part of the row.
  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final scale = _scale;
    if (scale != 1) transform.multiply(_transformAt(scale));
    super.applyPaintTransform(child, transform);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final scale = _scale;
    if (scale == 1) return super.hitTestChildren(result, position: position);

    return result.addWithPaintTransform(
      transform: _transformAt(scale),
      position: position,
      hitTest: (innerResult, innerPosition) =>
          super.hitTestChildren(innerResult, position: innerPosition),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final scale = _scale;
    if (scale == 1 || child == null) {
      super.paint(context, offset);
      return;
    }

    context.pushTransform(
      needsCompositing,
      offset,
      _transformAt(scale),
      (inner, innerOffset) => super.paint(inner, innerOffset),
    );
  }
}

/// Wraps every row a [ListView.builder] produces in a [WearListItem].
IndexedWidgetBuilder wearScaledItems(
  ScrollController controller,
  IndexedWidgetBuilder builder,
) {
  return (context, index) => WearListItem(
    scrollController: controller,
    child: builder(context, index),
  );
}

/// Wraps a fixed list of rows in [WearListItem]s.
List<Widget> wearScaledChildren(
  ScrollController controller,
  List<Widget> children,
) {
  return [
    for (final child in children)
      WearListItem(scrollController: controller, child: child),
  ];
}

/// Room below a wear list so its last row can be brought to the middle of the
/// glass, where the screen is widest and the eye is.
///
/// Without it a list stops the moment its last row appears at the bottom edge,
/// which is the worst place on a round screen to have to read it. There is no
/// matching room on top: the first row is already where it should be when the
/// list opens, and padding above it only buys the ability to scroll up into
/// nothing.
EdgeInsets wearListPadding(WearDisplay display) {
  if (!display.isRound) return EdgeInsets.zero;

  final content = display.sizeDp.shortestSide * (1 - 2 * kWearRoundInsetFactor);
  return EdgeInsets.only(bottom: content * _centringFraction);
}

/// Enough to bring a row of ordinary height to the middle, not so much that
/// the list opens on empty space.
const double _centringFraction = 0.3;
