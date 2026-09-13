import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:bsharp/wear/widgets/wear_launcher_row.dart';
import 'package:bsharp/wear/widgets/wear_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WearLauncherRow', () {
    testWidgets(
      'a long section title renders without ellipsis at 227dp',
      (tester) async {
        tester.view.physicalSize = const Size(227, 227);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        const longTitle = 'Trabalhos de casa';

        await tester.pumpWidget(
          MaterialApp(
            home: WearDisplayScope(
              display: const WearDisplay(
                shape: WearScreenShape.round,
                sizeDp: Size(227, 227),
              ),
              child: Scaffold(
                body: WearLauncherRow(
                  icon: Icons.campaign,
                  title: longTitle,
                  summary: 'summary',
                  onTap: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final paragraph =
            tester.renderObject(find.text(longTitle)) as RenderParagraph;
        expect(paragraph.didExceedMaxLines, isFalse);
      },
    );
  });
}
