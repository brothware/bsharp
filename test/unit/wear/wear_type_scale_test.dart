import 'dart:io';

import 'package:bsharp/presentation/common/theme/app_theme.dart';
import 'package:bsharp/wear/wear_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('wear text theme floors', () {
    test('no style in the wear text theme is below the 10sp floor', () {
      final theme = wearTheme(AppTheme.light());
      final textTheme = theme.textTheme;
      final styles = <String, TextStyle?>{
        'displayLarge': textTheme.displayLarge,
        'displayMedium': textTheme.displayMedium,
        'displaySmall': textTheme.displaySmall,
        'headlineLarge': textTheme.headlineLarge,
        'headlineMedium': textTheme.headlineMedium,
        'headlineSmall': textTheme.headlineSmall,
        'titleLarge': textTheme.titleLarge,
        'titleMedium': textTheme.titleMedium,
        'titleSmall': textTheme.titleSmall,
        'bodyLarge': textTheme.bodyLarge,
        'bodyMedium': textTheme.bodyMedium,
        'bodySmall': textTheme.bodySmall,
        'labelLarge': textTheme.labelLarge,
        'labelMedium': textTheme.labelMedium,
        'labelSmall': textTheme.labelSmall,
      };

      for (final entry in styles.entries) {
        final fontSize = entry.value?.fontSize;
        if (fontSize == null) continue;
        expect(
          fontSize,
          greaterThanOrEqualTo(10),
          reason: '${entry.key} is $fontSize, below the 10sp floor',
        );
      }
    });

    test('the essential wear roles match the specified scale', () {
      final theme = wearTheme(AppTheme.light());
      final textTheme = theme.textTheme;

      expect(textTheme.displaySmall?.fontSize, 22);
      expect(textTheme.titleMedium?.fontSize, 16);
      expect(textTheme.bodyLarge?.fontSize, 14);
      expect(textTheme.bodyMedium?.fontSize, 13);
      expect(textTheme.labelMedium?.fontSize, 12);
      expect(textTheme.labelSmall?.fontSize, 10);
    });

    test('no lib/wear source file has a fontSize literal below 10', () {
      final wearDir = Directory('lib/wear');
      final offenders = <String>[];
      final pattern = RegExp(r'fontSize:\s*(-?\d+(?:\.\d+)?)');

      for (final entity in wearDir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final content = entity.readAsStringSync();
        for (final match in pattern.allMatches(content)) {
          final value = double.parse(match.group(1)!);
          if (value < 10) {
            offenders.add('${entity.path}: fontSize: ${match.group(1)}');
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'fontSize literals below the 10sp floor: $offenders',
      );
    });
  });
}
