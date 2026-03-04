import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/screenshot.dart';

class WearRobot {
  WearRobot(this.tester, this.binding, this.device);

  final WidgetTester tester;
  final IntegrationTestWidgetsFlutterBinding binding;
  final String device;

  static const _tileNames = [
    'schedule_tile',
    'grades_tile',
    'attendance_tile',
    'homework_tile',
    'tests_tile',
    'notes_tile',
    'messages_tile',
    'bulletins_tile',
    'settings_tile',
  ];

  Future<void> captureAllTiles() async {
    await tester.takeAndCompareScreenshot(
      binding: binding,
      device: device,
      name: _tileNames.first,
    );

    for (var i = 1; i < _tileNames.length; i++) {
      await _swipeUp();
      await tester.takeAndCompareScreenshot(
        binding: binding,
        device: device,
        name: _tileNames[i],
      );
    }
  }

  Future<void> _swipeUp() async {
    final center = tester.getCenter(find.byType(PageView));
    await tester.flingFrom(center, const Offset(0, -300), 800);
    await tester.pumpAndSettle();
  }
}
