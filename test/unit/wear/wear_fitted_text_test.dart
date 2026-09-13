import 'dart:io';

import 'package:bsharp/wear/widgets/wear_fitted_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _style = TextStyle(fontSize: 14);
const _longWord = 'Nadchodzace';

double _naturalWidth(String text, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  return painter.width;
}

Future<double> _renderedFontSize(WidgetTester tester, double boxWidth) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: boxWidth,
            child: const WearFittedText(_longWord, style: _style),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return tester.widget<Text>(find.byType(Text)).style!.fontSize!;
}

void main() {
  group('WearFittedText', () {
    testWidgets('a label that fits keeps its full size', (tester) async {
      final size = await _renderedFontSize(
        tester,
        _naturalWidth(_longWord, _style) * 2,
      );

      expect(size, _style.fontSize);
    });

    testWidgets('a label that is slightly too wide shrinks to fit', (
      tester,
    ) async {
      final size = await _renderedFontSize(
        tester,
        _naturalWidth(_longWord, _style) * 0.85,
      );

      expect(size, lessThan(_style.fontSize!));
      expect(size, greaterThan(wearMinFontSizeSp));
    });

    testWidgets('a label never shrinks past the legibility floor', (
      tester,
    ) async {
      final size = await _renderedFontSize(
        tester,
        _naturalWidth(_longWord, _style) * 0.2,
      );

      expect(size, wearMinFontSizeSp);
    });

    testWidgets('a long word is never broken across lines', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: _naturalWidth(_longWord, _style) * 0.85,
                child: const WearFittedText(
                  _longWord,
                  style: _style,
                  maxLines: 2,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final painter = TextPainter(
        text: TextSpan(
          text: _longWord,
          style: tester.widget<Text>(find.byType(Text)).style,
        ),
        textDirection: TextDirection.ltr,
        maxLines: 2,
      )..layout(maxWidth: _naturalWidth(_longWord, _style) * 0.85);

      expect(
        painter.computeLineMetrics().length,
        1,
        reason:
            'a single word has no space to wrap at, so allowing a second line '
            'splits it mid-word instead of choosing a size that fits',
      );
    });

    test('no wear label ellipsises without trying to fit first', () {
      final offenders = <String>[];

      for (final entity in Directory('lib/wear').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.endsWith('wear_fitted_text.dart')) continue;
        if (entity.readAsStringSync().contains('TextOverflow.ellipsis')) {
          offenders.add(entity.path);
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'these wear files cut a label off at the first size that does not '
            'fit; use WearFittedText so it shrinks to the legibility floor '
            'before any text is lost: $offenders',
      );
    });
  });
}
