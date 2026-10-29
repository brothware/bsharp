import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const wearTextFloorSp = 12.0;

/// Every paragraph on screen whose drawn size, after any FittedBox above it
/// scaled it down, is under the WO-V14 floor. Text a scaling list shrinks at
/// the rim is Wear's own pattern and not counted; only FittedBox is.
List<String> textBelowFloor(WidgetTester tester) {
  final tooSmall = <String>[];
  void visit(RenderObject node) {
    // Icon draws its glyph as text in the icon font; it is not text to read.
    final isIcon =
        node is RenderParagraph &&
        (node.text.style?.fontFamily?.startsWith('MaterialIcons') ?? false);
    if (node is RenderParagraph && !isIcon) {
      final fontSize = node.text.style?.fontSize;
      if (fontSize != null) {
        final drawn = fontSize * _fittedScaleAbove(node);
        if (drawn < wearTextFloorSp - 0.05) {
          tooSmall.add(
            '"${node.text.toPlainText()}" ${drawn.toStringAsFixed(1)}sp',
          );
        }
      }
    }
    node.visitChildren(visit);
  }

  tester.binding.renderViews.forEach(visit);
  return tooSmall;
}

double _fittedScaleAbove(RenderObject node) {
  var scale = 1.0;
  RenderObject? current = node;
  while (current != null) {
    final parent = current.parent;
    if (parent is RenderFittedBox && current is RenderBox && current.hasSize) {
      final child = current.size;
      if (child.width > 0 && child.height > 0) {
        final fit = [
          parent.size.width / child.width,
          parent.size.height / child.height,
        ].reduce((a, b) => a < b ? a : b);
        if (fit < 1) {
          scale *= fit;
        }
      }
    }
    current = parent;
  }
  return scale;
}
