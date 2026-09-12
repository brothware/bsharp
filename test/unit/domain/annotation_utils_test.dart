import 'package:bsharp/core/constants/semantic_color.dart';
import 'package:bsharp/core/constants/semantic_palette.dart';
import 'package:bsharp/domain/annotation_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('annotationStyle', () {
    test('maps type 1 to the praise icon and status present colour', () {
      final style = annotationStyle(1, brightness: Brightness.light);
      expect(style.icon, Icons.emoji_events_outlined);
      expect(
        style.color,
        SemanticPalette.resolve(SemanticColor.statusPresent, Brightness.light),
      );
    });

    test('maps type 2 to the remark icon and status late colour', () {
      final style = annotationStyle(2, brightness: Brightness.light);
      expect(style.icon, Icons.warning_amber_outlined);
      expect(
        style.color,
        SemanticPalette.resolve(SemanticColor.statusLate, Brightness.light),
      );
    });

    test('maps any other type to the info icon and status excused colour', () {
      final style = annotationStyle(3, brightness: Brightness.light);
      expect(style.icon, Icons.info_outlined);
      expect(
        style.color,
        SemanticPalette.resolve(SemanticColor.statusExcused, Brightness.light),
      );
    });

    test('resolves a different colour for light and dark brightness', () {
      final lightStyle = annotationStyle(1, brightness: Brightness.light);
      final darkStyle = annotationStyle(1, brightness: Brightness.dark);
      expect(lightStyle.color, isNot(darkStyle.color));
    });
  });
}
