import 'dart:math' as math;

import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:bsharp/wear/widgets/wear_pin_dial.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _minTouchTarget = 48.0;
const _layoutTolerance = 0.01;
const _keyFaceInset = 4.0;
const _digits = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'];

typedef _Screen = ({WearScreenShape shape, Size size});

const _screens = <_Screen>[
  (shape: WearScreenShape.round, size: Size(192, 192)),
  (shape: WearScreenShape.round, size: Size(227, 227)),
  (shape: WearScreenShape.round, size: Size(454, 454)),
  (shape: WearScreenShape.rectangular, size: Size(192, 192)),
  (shape: WearScreenShape.rectangular, size: Size(198, 242)),
  (shape: WearScreenShape.rectangular, size: Size(320, 320)),
];

String _describe(_Screen screen) =>
    '${screen.shape.name} ${screen.size.width.toInt()}x'
    '${screen.size.height.toInt()}';

bool _isOnGlass(Offset point, _Screen screen) {
  final bounds = Offset.zero & screen.size;
  if (screen.shape == WearScreenShape.rectangular) {
    return bounds.inflate(_layoutTolerance).contains(point);
  }
  return (point - bounds.center).distance <=
      bounds.shortestSide / 2 + _layoutTolerance;
}

Finder _keyOf(String digit) =>
    find.ancestor(of: find.text(digit), matching: find.byType(InkWell));

Finder _dots({required bool isFilled}) => find.byWidgetPredicate(
  (widget) => widget is WearPinDot && widget.isFilled == isFilled,
);

Future<void> _pumpDial(
  WidgetTester tester,
  _Screen screen, {
  int enteredCount = 0,
  String? error,
  ValueChanged<String>? onKeyTap,
}) async {
  tester.view.physicalSize = screen.size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: WearPinDial(
          shape: screen.shape,
          prompt: 'Enter parent PIN',
          error: error,
          enteredCount: enteredCount,
          pinLength: 4,
          onKeyTap: onKeyTap ?? (_) {},
        ),
      ),
    ),
  );
}

void main() {
  group('wearDialKeyCentres', () {
    for (final screen in _screens) {
      test('${_describe(screen)}: ten keys on the glass, 48dp apart', () {
        final centres = wearDialKeyCentres(
          size: screen.size,
          shape: screen.shape,
        );

        expect(centres, hasLength(_digits.length));
        for (var index = 0; index < centres.length; index++) {
          for (var other = index + 1; other < centres.length; other++) {
            expect(
              (centres[other] - centres[index]).distance,
              greaterThanOrEqualTo(_minTouchTarget - _layoutTolerance),
              reason: 'key $index overlaps key $other',
            );
          }
          expect(
            _isOnGlass(centres[index], screen),
            isTrue,
            reason: 'key $index at ${centres[index]} is off the glass',
          );
        }
      });
    }

    test('a ring starts right of twelve and ends mirrored left of it', () {
      const size = Size(227, 227);
      final centres = wearDialKeyCentres(
        size: size,
        shape: WearScreenShape.round,
      );
      final middle = size.width / 2;

      expect(centres.first.dx, greaterThan(middle));
      expect(centres.first.dy, lessThan(size.height / 4));
      expect(centres.last.dy, closeTo(centres.first.dy, _layoutTolerance));
      expect(
        middle - centres.last.dx,
        closeTo(centres.first.dx - middle, _layoutTolerance),
      );
    });

    test('a frame runs clockwise from the top-left corner', () {
      const size = Size(198, 242);
      final centres = wearDialKeyCentres(
        size: size,
        shape: WearScreenShape.rectangular,
      );
      const half = _minTouchTarget / 2;

      expect(centres[0], const Offset(half, half));
      expect(centres[2], Offset(size.width - half, half));
      expect(centres[5], Offset(size.width - half, size.height - half));
      expect(centres[7], Offset(half, size.height - half));
      expect(centres[3].dx, size.width - half);
      expect(centres[3].dy, lessThan(centres[4].dy));
      expect(centres[8].dx, half);
      expect(centres[8].dy, greaterThan(centres[9].dy));
    });

    test('a frame reaches into the corners a ring would waste', () {
      const size = Size(192, 192);
      double farthest(WearScreenShape shape) =>
          wearDialKeyCentres(size: size, shape: shape)
              .map((centre) => (centre - size.center(Offset.zero)).distance)
              .reduce(math.max);

      expect(
        farthest(WearScreenShape.rectangular),
        greaterThan(farthest(WearScreenShape.round)),
      );
    });
  });

  group('WearPinDial', () {
    for (final screen in _screens) {
      testWidgets('${_describe(screen)}: every key is 48dp and on the glass', (
        tester,
      ) async {
        await _pumpDial(tester, screen, enteredCount: 1);

        for (final digit in _digits) {
          expect(
            tester.getRect(_keyOf(digit)).shortestSide,
            greaterThanOrEqualTo(_minTouchTarget - _layoutTolerance),
          );
          final glyph = tester.getRect(find.text(digit));
          for (final corner in [
            glyph.topLeft,
            glyph.topRight,
            glyph.bottomLeft,
            glyph.bottomRight,
          ]) {
            expect(
              _isOnGlass(corner, screen),
              isTrue,
              reason: 'digit $digit at $glyph is off the glass',
            );
          }
        }
        expect(
          tester.getRect(find.byTooltip(t.common.delete)).shortestSide,
          greaterThanOrEqualTo(_minTouchTarget - _layoutTolerance),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('${_describe(screen)}: the prompt stays clear of the keys', (
        tester,
      ) async {
        await _pumpDial(tester, screen);

        final paragraph = tester.renderObject<RenderParagraph>(
          find.text('Enter parent PIN'),
        );
        final origin = paragraph.localToGlobal(Offset.zero);
        final lines = paragraph.getBoxesForSelection(
          TextSelection(
            baseOffset: 0,
            extentOffset: paragraph.text.toPlainText().length,
          ),
        );
        for (final digit in _digits) {
          final face = tester.getRect(_keyOf(digit)).deflate(_keyFaceInset);
          for (final line in lines) {
            final box = line.toRect().shift(origin);
            expect(
              box.overlaps(face),
              isFalse,
              reason: 'the prompt line $box runs under key $digit at $face',
            );
          }
        }
      });
    }

    testWidgets('shows the prompt until the first digit, then the dots', (
      tester,
    ) async {
      const screen = (shape: WearScreenShape.round, size: Size(227, 227));
      await _pumpDial(tester, screen);

      expect(find.text('Enter parent PIN'), findsOneWidget);
      expect(find.byTooltip(t.common.delete), findsNothing);

      await _pumpDial(tester, screen, enteredCount: 2);

      expect(find.text('Enter parent PIN'), findsNothing);
      expect(find.byTooltip(t.common.delete), findsOneWidget);
      expect(_dots(isFilled: true), findsNWidgets(2));
      expect(_dots(isFilled: false), findsNWidgets(2));
    });

    testWidgets('an error takes the place of the prompt', (tester) async {
      const screen = (shape: WearScreenShape.round, size: Size(227, 227));
      await _pumpDial(tester, screen, error: 'Wrong PIN');

      expect(find.text('Wrong PIN'), findsOneWidget);
      expect(find.text('Enter parent PIN'), findsNothing);
      expect(
        tester
            .getSemantics(find.text('Wrong PIN'))
            .flagsCollection
            .isLiveRegion,
        isTrue,
      );
    });

    testWidgets('digits and delete report their keys', (tester) async {
      const screen = (shape: WearScreenShape.rectangular, size: Size(227, 227));
      final taps = <String>[];
      await _pumpDial(tester, screen, enteredCount: 1, onKeyTap: taps.add);

      await tester.tap(find.text('7'));
      await tester.tap(find.byTooltip(t.common.delete));

      expect(taps, ['7', WearPinDial.deleteKey]);
    });
  });
}
