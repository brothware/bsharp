import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'every scrollable wear screen hands its controller to the edge '
    'scrollbar',
    () {
      final screensDir = Directory('lib/wear/screens');
      final offenders = <String>[];
      final scrollableTypes = RegExp(
        'ListView|CustomScrollView|SingleChildScrollView',
      );

      for (final entity in screensDir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final content = entity.readAsStringSync();
        if (!scrollableTypes.hasMatch(content)) continue;
        if (!content.contains('scrollController:') &&
            !content.contains('WearEdgeScrollbar')) {
          offenders.add(entity.path);
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'these wear screens have a scrollable but no WearOsScrollbar, '
            'so the crown cannot scroll them: $offenders',
      );
    },
  );

  test('no wear screen draws a second Material scrollbar', () {
    final offenders = <String>[];
    for (final dir in ['lib/wear/screens', 'lib/wear/widgets']) {
      for (final entity in Directory(dir).listSync()) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final source = entity.readAsStringSync();
        if (RegExp(r'(?<!WearOs)(?<!WearEdge)\bScrollbar\(').hasMatch(source)) {
          offenders.add(entity.path);
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'WearOsScrollbar already draws the curved indicator, so a Material '
          'Scrollbar renders a second one beside it: $offenders',
    );
  });
}
