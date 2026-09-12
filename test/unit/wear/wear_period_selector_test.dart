import 'package:bsharp/wear/widgets/wear_period_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WearPeriodSelector', () {
    testWidgets('renders label and subLabel', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WearPeriodSelector(
              label: '12.09',
              subLabel: 'Friday',
              onPrevious: () {},
              onNext: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('12.09'), findsOneWidget);
      expect(find.text('Friday'), findsOneWidget);
    });

    testWidgets('renders without subLabel', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WearPeriodSelector(
              label: 'Semester 1',
              onPrevious: () {},
              onNext: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Semester 1'), findsOneWidget);
    });

    testWidgets('both chevrons are at least 48dp', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WearPeriodSelector(
              label: 'Label',
              onPrevious: () {},
              onNext: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      final finder = find.byType(InkWell);
      expect(finder, findsNWidgets(2));

      for (final element in finder.evaluate()) {
        final size = tester.getSize(find.byWidget(element.widget));
        final smallerAxis = size.width < size.height ? size.width : size.height;
        expect(smallerAxis, greaterThanOrEqualTo(48.0));
      }
    });

    testWidgets('tapping previous fires onPrevious', (tester) async {
      var previousTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WearPeriodSelector(
              label: 'Label',
              onPrevious: () => previousTapped = true,
              onNext: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pump();

      expect(previousTapped, isTrue);
    });

    testWidgets('tapping next fires onNext', (tester) async {
      var nextTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WearPeriodSelector(
              label: 'Label',
              onPrevious: () {},
              onNext: () => nextTapped = true,
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pump();

      expect(nextTapped, isTrue);
    });
  });
}
