import 'package:bsharp/wear/screens/wear_home.dart';
import 'package:bsharp/wear/screens/wear_tests_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

Future<void> _typeOnSystemInput(WidgetTester tester, String text) async {
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('pl.brothware.bsharp/wear'),
    (call) async => call.method == 'requestTextInput' ? text : null,
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('pl.brothware.bsharp/wear'),
      null,
    ),
  );
  await tester.tap(find.byType(TextField));
  await tester.pumpAndSettle();
}

Future<void> _pressStepButton(WidgetTester tester, String label) async {
  tester
      .widget<FilledButton>(
        find.ancestor(
          of: find.text(label),
          matching: find.byType(FilledButton),
        ),
      )
      .onPressed!();
  await tester.pumpAndSettle();
}

String _fieldText(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).controller!.text;

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

    testWidgets('setup comes back on its step with what was typed', (
      tester,
    ) async {
      await pumpWearApp(tester, _watch);
      await tester.scrollUntilVisible(find.text('Type it on the watch'), 40);
      tester
          .widget<TextButton>(
            find.ancestor(
              of: find.text('Type it on the watch'),
              matching: find.byType(TextButton),
            ),
          )
          .onPressed!();
      await tester.pumpAndSettle();
      await _openRow(tester, 'Mobireg');
      await _typeOnSystemInput(tester, 'osm-wroclaw');
      await _pressStepButton(tester, 'Next');
      await _typeOnSystemInput(tester, 'jan');

      await tester.restartAndRestore();
      await pumpWearUntil(tester, find.byType(TextField));

      expect(_fieldText(tester), 'jan');
      Navigator.of(tester.element(find.byType(TextField))).maybePop();
      await tester.pumpAndSettle();
      expect(_fieldText(tester), 'osm-wroclaw');
    });

    testWidgets('adding another account comes back with what was typed', (
      tester,
    ) async {
      await openWearDemo(tester, _watch);
      await _openRow(tester, 'Settings');
      await _openRow(tester, 'Add account');
      await _openRow(tester, 'Mobireg');
      await _typeOnSystemInput(tester, 'osm-wroclaw');
      await _pressStepButton(tester, 'Next');
      await _typeOnSystemInput(tester, 'jan');

      await tester.restartAndRestore();
      await pumpWearUntil(tester, find.byType(TextField));

      expect(_fieldText(tester), 'jan');
      Navigator.of(tester.element(find.byType(TextField))).maybePop();
      await tester.pumpAndSettle();
      expect(_fieldText(tester), 'osm-wroclaw');
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
