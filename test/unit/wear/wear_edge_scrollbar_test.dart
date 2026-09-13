import 'dart:math' as math;

import 'package:bsharp/presentation/common/theme/app_theme.dart';
import 'package:bsharp/wear/wear_app.dart';
import 'package:bsharp/wear/widgets/wear_edge_scrollbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wear_os_scrollbar/wear_os_scrollbar.dart';

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

double _contrastRatio(Color a, Color b) {
  final lighter = math.max(_luminance(a), _luminance(b));
  final darker = math.min(_luminance(a), _luminance(b));
  return (lighter + 0.05) / (darker + 0.05);
}

Future<WearOsScrollbar> _pumpBar(WidgetTester tester, ThemeData theme) async {
  final controller = ScrollController();
  addTearDown(controller.dispose);

  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: WearEdgeScrollbar(
          controller: controller,
          child: ListView(
            controller: controller,
            children: [
              for (var i = 0; i < 40; i++) const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return tester.widget<WearOsScrollbar>(find.byType(WearOsScrollbar));
}

void main() {
  group('WearEdgeScrollbar', () {
    for (final (name, theme) in [
      ('dark', wearTheme(AppTheme.dark())),
      ('light', wearTheme(AppTheme.light())),
    ]) {
      testWidgets('$name: the track reads against the surface behind it', (
        tester,
      ) async {
        final bar = await _pumpBar(tester, theme);
        final surface = theme.colorScheme.surface;
        final track = Color.alphaBlend(bar.backgroundColor, surface);

        expect(
          track,
          isNot(surface),
          reason:
              'the wear theme flattens every surface container onto the '
              'background, so a container colour paints the track in the '
              'background colour and leaves the thumb floating alone',
        );
        expect(_contrastRatio(track, surface), greaterThan(1.5));
      });

      testWidgets('$name: the thumb reads as a graphical object', (
        tester,
      ) async {
        final bar = await _pumpBar(tester, theme);
        expect(
          _contrastRatio(bar.indicatorColor, theme.colorScheme.surface),
          greaterThanOrEqualTo(3),
        );
      });

      testWidgets('$name: the track spans most of the screen height', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(454, 454);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        final bar = await _pumpBar(tester, theme);
        final halfSweep = bar.totalAngle * math.pi / 360;
        final radius = 227 / 2 - bar.strokeWidth / 2 - bar.marginRight;

        expect(
          2 * radius * math.sin(halfSweep),
          greaterThanOrEqualTo(227 * 0.45),
          reason:
              'the package default of 30 degrees spans a fifth of the screen, '
              'which leaves the thumb barely moving between the top and the '
              'bottom of a long message',
        );
      });
    }
  });
}
