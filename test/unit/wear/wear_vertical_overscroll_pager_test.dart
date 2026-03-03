import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bsharp/wear/widgets/wear_vertical_overscroll_pager.dart';

void main() {
  group('WearVerticalOverscrollPager', () {
    testWidgets('fires onNext on bottom overscroll', (tester) async {
      var nextCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WearVerticalOverscrollPager(
              threshold: 50,
              onPrevious: () {},
              onNext: () => nextCalled = true,
              child: ListView(
                children: const [SizedBox(height: 100, child: Text('Item'))],
              ),
            ),
          ),
        ),
      );

      final listFinder = find.byType(ListView);
      await tester.fling(listFinder, const Offset(0, -300), 1000);
      await tester.pumpAndSettle();

      expect(nextCalled, isTrue);
    });

    testWidgets('fires onPrevious on top overscroll', (tester) async {
      var previousCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WearVerticalOverscrollPager(
              threshold: 50,
              onPrevious: () => previousCalled = true,
              onNext: () {},
              child: ListView(
                children: const [SizedBox(height: 100, child: Text('Item'))],
              ),
            ),
          ),
        ),
      );

      final listFinder = find.byType(ListView);
      await tester.fling(listFinder, const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      expect(previousCalled, isTrue);
    });

    testWidgets('does not fire when overscroll is below threshold', (
      tester,
    ) async {
      var previousCalled = false;
      var nextCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WearVerticalOverscrollPager(
              threshold: 5000,
              onPrevious: () => previousCalled = true,
              onNext: () => nextCalled = true,
              child: ListView(
                children: const [SizedBox(height: 100, child: Text('Item'))],
              ),
            ),
          ),
        ),
      );

      final listFinder = find.byType(ListView);
      await tester.drag(listFinder, const Offset(0, -10));
      await tester.pumpAndSettle();

      expect(previousCalled, isFalse);
      expect(nextCalled, isFalse);
    });

    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WearVerticalOverscrollPager(
              onPrevious: () {},
              onNext: () {},
              child: const Text('Hello'),
            ),
          ),
        ),
      );

      expect(find.text('Hello'), findsOneWidget);
    });
  });
}
