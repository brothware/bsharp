import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/demo_app.dart';
import 'helpers/screenshot.dart';
import 'robots/phone_robot.dart';

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
    testWidgets('tablet $variant', (tester) async {
      final container = await pumpDemoApp(
        tester,
        themeMode: themeMode,
        locale: locale,
      );
      addTearDown(container.dispose);
      await binding.convertFlutterSurfaceToImage();

      final robot = PhoneRobot(tester, binding, 'tablet/$variant');

      await robot.captureDashboard();
      await robot.captureSchedule();
      await robot.captureGrades();
      await robot.captureAttendance();
      await robot.captureHomework();
      await robot.captureTests();
      await robot.captureNotes();
      await robot.captureBulletins();
      await robot.captureMessages();
      await robot.captureSettings();
    });
  }
}
