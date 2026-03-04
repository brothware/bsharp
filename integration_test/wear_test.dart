import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/demo_wear_app.dart';
import 'helpers/screenshot.dart';
import 'robots/wear_robot.dart';

const List<(String, ThemeMode, String)> _variants = [
  ('light-en', ThemeMode.light, 'en'),
  ('light-pl', ThemeMode.light, 'pl'),
  ('dark-en', ThemeMode.dark, 'en'),
  ('dark-pl', ThemeMode.dark, 'pl'),
];

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setupGoldenComparator();

  for (final (variant, themeMode, locale) in _variants) {
    testWidgets('wear $variant', (tester) async {
      final container = await pumpDemoWearApp(
        tester,
        themeMode: themeMode,
        locale: locale,
      );
      addTearDown(container.dispose);
      await binding.convertFlutterSurfaceToImage();

      final robot = WearRobot(tester, binding, 'watch/$variant');
      await robot.captureAllTiles();
    });
  }
}
