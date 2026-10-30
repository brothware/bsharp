import 'package:bsharp/wear/screens/wear_home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'wear_demo_harness.dart';
import 'wear_text_size_probe.dart';

const _watchSizesDp = [Size(227, 227), Size(192, 192)];
const _sections = [
  'Schedule',
  'Grades',
  'Attendance',
  'Tests',
  'Homework',
  'Messages',
  'Announcements',
  'Settings',
];

Future<void> _expectGuidelines(WidgetTester tester, String where) async {
  for (final (name, guideline) in [
    ('labelled tap targets', labeledTapTargetGuideline),
    ('text contrast', textContrastGuideline),
  ]) {
    await expectLater(
      tester,
      meetsGuideline(guideline),
      reason: '$where: $name',
    );
  }
  _expectTapTargetsAtLeast48dp(tester, where);
  expect(
    textBelowFloor(tester),
    isEmpty,
    reason: '$where: text drawn under 12sp (WO-V14)',
  );
}

/// androidTapTargetGuideline measures what is on screen, after the clip of
/// the list and the shrink Wear's scaling lists give rows near the rim. A
/// target's own laid-out size is what WO-V2 asks about, so this measures that.
void _expectTapTargetsAtLeast48dp(WidgetTester tester, String where) {
  const minTargetDp = 48.0;
  final targets = find.byWidgetPredicate(
    (widget) => switch (widget) {
      InkResponse(:final onTap) => onTap != null,
      GestureDetector(:final onTap) => onTap != null,
      ButtonStyleButton(:final onPressed) => onPressed != null,
      IconButton(:final onPressed) => onPressed != null,
      _ => false,
    },
  );
  final tooSmall = [
    for (final element in targets.evaluate())
      if (tester.getSize(find.byElementPredicate((e) => e == element))
          case final size
          when size.width < minTargetDp || size.height < minTargetDp)
        '${element.widget.runtimeType} $size',
  ];
  expect(tooSmall, isEmpty, reason: '$where: targets under 48dp');
}

void main() {
  for (final watchSizeDp in _watchSizesDp) {
    final size = '${watchSizeDp.width.toInt()}dp';

    testWidgets('$size: the dashboard meets the accessibility guidelines', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await openWearDemo(tester, watchSizeDp);

      await _expectGuidelines(tester, '$size dashboard');
      handle.dispose();
    });

    for (final section in _sections) {
      testWidgets('$size: $section meets the accessibility guidelines', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await openWearDemo(tester, watchSizeDp);
        final row = find.text(section);
        await tester.scrollUntilVisible(row, 60);
        tester
            .widget<InkWell>(
              find
                  .ancestor(of: row.first, matching: find.byType(InkWell))
                  .first,
            )
            .onTap!();
        await tester.pumpAndSettle();
        expect(find.byType(WearHome), findsNothing, reason: '$section opened');

        await _expectGuidelines(tester, '$size $section');
        handle.dispose();
      });
    }
  }
}
