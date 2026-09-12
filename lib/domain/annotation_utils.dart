import 'package:bsharp/core/constants/semantic_color.dart';
import 'package:bsharp/core/constants/semantic_palette.dart';
import 'package:flutter/material.dart';

({IconData icon, Color color}) annotationStyle(
  int type, {
  required Brightness brightness,
}) {
  final (icon, token) = switch (type) {
    1 => (Icons.emoji_events_outlined, SemanticColor.statusPresent),
    2 => (Icons.warning_amber_outlined, SemanticColor.statusLate),
    _ => (Icons.info_outlined, SemanticColor.statusExcused),
  };
  return (icon: icon, color: SemanticPalette.resolve(token, brightness));
}
