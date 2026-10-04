import 'package:flutter_test/flutter_test.dart';

Future<void> tapLinkText(WidgetTester tester, String text) async {
  await tester.tapOnText(find.textRange.ofSubstring(text));
  await tester.pumpAndSettle();
}
