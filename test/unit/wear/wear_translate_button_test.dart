import 'package:bsharp/app/translation_provider.dart';
import 'package:bsharp/wear/widgets/wear_translate_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the translate link is a 48dp, named touch target (WO-V2)', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [isTranslationAvailableProvider.overrideWithValue(true)],
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: WearTranslateButton(
                sourceText: 'Zebranie',
                onTranslated: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    final size = tester.getSize(
      find.ancestor(of: find.text('Translate'), matching: find.byType(InkWell)),
    );
    expect(size.height, greaterThanOrEqualTo(48));
    expect(size.width, greaterThanOrEqualTo(48));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
