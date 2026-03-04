import 'package:bsharp/l10n/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/screenshot.dart';

class PhoneRobot {
  PhoneRobot(this.tester, this.binding, this.device);

  final WidgetTester tester;
  final IntegrationTestWidgetsFlutterBinding binding;
  final String device;

  Future<void> captureDashboard() async {
    await tester.takeAndCompareScreenshot(
      binding: binding,
      device: device,
      name: 'dashboard',
    );
  }

  Future<void> captureSchedule() async {
    await _navigateTo(t.nav.schedule);
    await tester.takeAndCompareScreenshot(
      binding: binding,
      device: device,
      name: 'schedule',
    );
  }

  Future<void> captureGrades() async {
    await _navigateTo(t.nav.grades);
    await tester.takeAndCompareScreenshot(
      binding: binding,
      device: device,
      name: 'grades',
    );
  }

  Future<void> captureAttendance() async {
    await _navigateTo(t.nav.attendance);
    await tester.takeAndCompareScreenshot(
      binding: binding,
      device: device,
      name: 'attendance',
    );
  }

  Future<void> captureHomework() async {
    await _navigateTo(t.nav.homework);
    await tester.takeAndCompareScreenshot(
      binding: binding,
      device: device,
      name: 'homework',
    );
  }

  Future<void> captureTests() async {
    await _navigateTo(t.nav.tests);
    await tester.takeAndCompareScreenshot(
      binding: binding,
      device: device,
      name: 'tests',
    );
  }

  Future<void> captureNotes() async {
    await _navigateTo(t.nav.notes);
    await tester.takeAndCompareScreenshot(
      binding: binding,
      device: device,
      name: 'notes',
    );
  }

  Future<void> captureBulletins() async {
    await _navigateTo(t.nav.bulletins);
    await tester.takeAndCompareScreenshot(
      binding: binding,
      device: device,
      name: 'bulletins',
    );
  }

  Future<void> captureMessages() async {
    await tester.tap(find.byIcon(Icons.mail_outline).first);
    await tester.pumpAndSettle();
    await tester.takeAndCompareScreenshot(
      binding: binding,
      device: device,
      name: 'messages',
    );
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
  }

  Future<void> captureSettings() async {
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    await tester.takeAndCompareScreenshot(
      binding: binding,
      device: device,
      name: 'settings',
    );
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
  }

  Future<void> _navigateTo(String label) async {
    final moreButton = find.text(t.nav.more);
    if (moreButton.evaluate().isNotEmpty) {
      final directLabel = find.text(label);
      if (directLabel.evaluate().isNotEmpty) {
        await tester.tap(directLabel.last);
        await tester.pumpAndSettle();
      } else {
        await tester.tap(moreButton);
        await tester.pumpAndSettle();
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }
    } else {
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
    }
  }
}
