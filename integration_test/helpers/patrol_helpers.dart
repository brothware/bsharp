import 'package:bsharp/app/app.dart';
import 'package:bsharp/app/locale_provider.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> launchApp(PatrolIntegrationTester $) async {
  final prefs = await SharedPreferences.getInstance();

  final stored = prefs.getString('locale');
  final initialLocale =
      stored ?? LocaleNotifier.resolveSystemLocale().languageCode;
  await LocaleSettings.setLocaleRaw(initialLocale);

  await $.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: TranslationProvider(child: const BSharpApp()),
    ),
  );

  await $.pumpAndSettle(timeout: const Duration(seconds: 15));
}

Future<void> loginAndSync(PatrolIntegrationTester $) async {
  await $(find.text('Add account')).waitUntilVisible().tap();

  await $(find.widgetWithText(ListTile, 'Mobireg')).waitUntilVisible().tap();

  final fields = find.byType(TextField);
  await $.tester.enterText(fields.at(0), 'osm-wroclaw');
  await $.tester.enterText(fields.at(1), 'u');
  await $.tester.enterText(fields.at(2), 'p');
  await $.pumpAndSettle();

  await $(
    find.widgetWithText(FilledButton, 'Add account'),
  ).waitUntilVisible().tap();
  await $.pumpAndSettle(timeout: const Duration(seconds: 15));

  await $(
    find.widgetWithText(FilledButton, 'Continue'),
  ).waitUntilVisible().tap();
  await $.pumpAndSettle(timeout: const Duration(seconds: 15));
}

Future<void> navigateToSettings(PatrolIntegrationTester $) async {
  await $(find.byIcon(Icons.settings)).waitUntilVisible().tap();
  await $.pumpAndSettle();
}

Future<void> toggleNotification(
  PatrolIntegrationTester $,
  String categoryName,
) async {
  final toggle = find.ancestor(
    of: find.text(categoryName),
    matching: find.byType(SwitchListTile),
  );
  await $(toggle).waitUntilVisible().tap();
  await $.pumpAndSettle();
}

Future<void> goBack(PatrolIntegrationTester $) async {
  await $.tester.pageBack();
  await $.pumpAndSettle();
}
