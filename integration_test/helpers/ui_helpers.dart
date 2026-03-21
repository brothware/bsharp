import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> selectProvider(WidgetTester tester, String providerName) async {
  final tile = find.widgetWithText(ListTile, providerName);
  await tester.tap(tile);
  await tester.pumpAndSettle();
}

Future<void> enterCredentials(
  WidgetTester tester, {
  required String school,
  required String login,
  required String password,
}) async {
  final textFields = find.byType(TextField);

  await tester.enterText(textFields.at(0), school);
  await tester.enterText(textFields.at(1), login);
  await tester.enterText(textFields.at(2), password);
  await tester.pumpAndSettle();
}

Future<void> tapAddAccount(WidgetTester tester) async {
  final button = find.widgetWithText(FilledButton, 'Add account');
  await tester.tap(button);
  await tester.pumpAndSettle(const Duration(seconds: 5));
}

Future<void> tapContinue(WidgetTester tester) async {
  final button = find.widgetWithText(FilledButton, 'Continue');
  await tester.tap(button);
  await tester.pumpAndSettle(const Duration(seconds: 5));
}

Future<void> tapAddAccountOutlined(WidgetTester tester) async {
  final button = find.widgetWithText(OutlinedButton, 'Add account');
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> waitForSync(WidgetTester tester) async {
  await tester.pumpAndSettle(const Duration(seconds: 10));
}

Future<void> navigateToTab(WidgetTester tester, IconData icon) async {
  final tab = find.byIcon(icon);
  if (tab.evaluate().isNotEmpty) {
    await tester.tap(tab.last);
    await tester.pumpAndSettle();
  }
}
