import 'package:bsharp/wear/screens/wear_home.dart';
import 'package:bsharp/wear/screens/wear_tests_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'wear_demo_harness.dart';

const _watch = Size(227, 227);
const _homeScrollDp = 120.0;

ScrollPosition _homePosition(WidgetTester tester) => tester
    .state<ScrollableState>(
      find
          .descendant(
            of: find.byType(WearHome),
            matching: find.byType(Scrollable),
          )
          .first,
    )
    .position;

Future<void> _openRow(WidgetTester tester, String title) async {
  await tester.scrollUntilVisible(find.text(title), 40);
  tester
      .widget<InkWell>(
        find
            .ancestor(of: find.text(title), matching: find.byType(InkWell))
            .first,
      )
      .onTap!();
  await tester.pumpAndSettle();
}

void main() {
  group('state restoration (WO-V5)', () {
    testWidgets('the open section comes back after the process is killed', (
      tester,
    ) async {
      await openWearDemo(tester, _watch);
      await _openRow(tester, 'Tests');
      expect(find.byType(WearTestsDetailScreen), findsOneWidget);

      await tester.restartAndRestore();
      await pumpWearUntil(tester, find.byType(WearTestsDetailScreen));

      expect(find.byType(WearTestsDetailScreen), findsOneWidget);
    });

    testWidgets('home comes back scrolled where it was left', (tester) async {
      await openWearDemo(tester, _watch);
      _homePosition(tester).jumpTo(_homeScrollDp);
      await tester.pumpAndSettle();

      await tester.restartAndRestore();
      await pumpWearUntil(tester, find.byType(WearHome));
      await tester.pumpAndSettle();

      expect(_homePosition(tester).pixels, _homeScrollDp);
    });
  });
}
