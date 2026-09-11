import 'dart:math' as math;
import 'dart:ui';

import 'package:bsharp/core/constants/semantic_color.dart';
import 'package:bsharp/core/constants/semantic_palette.dart';
import 'package:bsharp/presentation/common/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

double _linear(double channel) {
  return channel <= 0.04045
      ? channel / 12.92
      : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
}

double _luminance(Color color) {
  return 0.2126 * _linear(color.r) +
      0.7152 * _linear(color.g) +
      0.0722 * _linear(color.b);
}

double contrastRatio(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final lighter = math.max(la, lb);
  final darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  const minimumRatio = 4.5;

  test('SemanticColor covers every shared token', () {
    expect(SemanticColor.values.length, 19);
    expect(SemanticPalette.light.keys.toSet(), SemanticColor.values.toSet());
    expect(SemanticPalette.dark.keys.toSet(), SemanticColor.values.toSet());
  });

  test('every light token is legible on the light surface', () {
    final surface = AppTheme.light().colorScheme.surface;
    for (final token in SemanticColor.values) {
      final ratio = contrastRatio(SemanticPalette.light[token]!, surface);
      expect(
        ratio,
        greaterThanOrEqualTo(minimumRatio),
        reason:
            '$token scores ${ratio.toStringAsFixed(2)} on the light surface',
      );
    }
  });

  test('every dark token is legible on the dark surface', () {
    final surface = AppTheme.dark().colorScheme.surface;
    for (final token in SemanticColor.values) {
      final ratio = contrastRatio(SemanticPalette.dark[token]!, surface);
      expect(
        ratio,
        greaterThanOrEqualTo(minimumRatio),
        reason: '$token scores ${ratio.toStringAsFixed(2)} on the dark surface',
      );
    }
  });

  test('every dark token is legible on the wear black surface', () {
    for (final token in SemanticColor.values) {
      final ratio = contrastRatio(
        SemanticPalette.dark[token]!,
        const Color(0xFF000000),
      );
      expect(
        ratio,
        greaterThanOrEqualTo(minimumRatio),
        reason: '$token scores ${ratio.toStringAsFixed(2)} on black',
      );
    }
  });
}
