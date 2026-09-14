import 'package:bsharp/wear/widgets/wear_period_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('WearPeriodSelector', () {
    testWidgets('renders label and subLabel', (tester) async {
      await tester.pumpWidget(
        _app(
          const WearPeriodSelector(label: 'Wrzesień', subLabel: 'Poniedziałek'),
        ),
      );
      await tester.pump();

      expect(find.text('Wrzesień'), findsOneWidget);
      expect(find.text('Poniedziałek'), findsOneWidget);
    });

    testWidgets('renders without subLabel', (tester) async {
      await tester.pumpWidget(
        _app(const WearPeriodSelector(label: 'Semestr I')),
      );
      await tester.pump();

      expect(find.text('Semestr I'), findsOneWidget);
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('a long label renders without ellipsis at 227dp', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(227, 227);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _app(const WearPeriodSelector(label: 'Pierwszy semestr')),
      );
      await tester.pump();

      final paragraph =
          tester.renderObject(find.text('Pierwszy semestr')) as RenderParagraph;
      expect(paragraph.didExceedMaxLines, isFalse);
    });

    testWidgets('carries no navigation of its own', (tester) async {
      await tester.pumpWidget(
        _app(const WearPeriodSelector(label: 'Wrzesień')),
      );
      await tester.pump();

      expect(
        find.byIcon(Icons.chevron_left),
        findsNothing,
        reason:
            'moving between periods belongs at the edges of the glass, where '
            'a round screen is at its widest, not in the header where it is '
            'at its narrowest',
      );
    });
  });
}
