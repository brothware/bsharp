@Tags(['patrol'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:bsharp/core/constants/app_constants.dart';
import 'package:bsharp/data/services/background_sync_scheduler.dart';
import 'package:bsharp/data/services/background_sync_task.dart';
import 'package:bsharp/data/services/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'helpers/patrol_helpers.dart';

void main() {
  late String mockBaseUrl;

  patrolSetUp(() async {
    mockBaseUrl = AppConstants.mobiregBaseUrl;
    assert(mockBaseUrl.isNotEmpty, 'MOBIREG_BASE_URL must be set');
    await _resetScenarios(mockBaseUrl);
  });

  patrolTearDown(() async {
    await _resetScenarios(AppConstants.mobiregBaseUrl);
  });

  patrolTest(
    'step 1: background sync task runs after login',
    ($) async {
      await launchApp($);
      await loginAndSync($);

      final task = BackgroundSyncTask(rescheduleOnComplete: false);
      final result = await task.execute();

      debugPrint('BackgroundSync first run result: $result');
      expect(result, isTrue, reason: 'First sync should succeed');
    },
  );

  patrolTest(
    'step 2: sync task detects new grade after scenario push',
    ($) async {
      await launchApp($);
      await loginAndSync($);

      final task = BackgroundSyncTask(rescheduleOnComplete: false);

      final firstResult = await task.execute();
      debugPrint('First sync result: $firstResult');
      expect(firstResult, isTrue);

      await _pushNewGrade(mockBaseUrl);

      final secondResult = await task.execute();
      debugPrint('Second sync result (after pushing grade): $secondResult');
      expect(secondResult, isTrue);
    },
  );

  patrolTest(
    'step 3: foreground sync triggers notification in shade',
    ($) async {
      await launchApp($);
      await loginAndSync($);

      await _grantNotificationPermission($);

      final task = BackgroundSyncTask(rescheduleOnComplete: false);
      await task.execute();

      await _pushNewGrade(mockBaseUrl);
      await task.execute();

      await $.platform.mobile.pressHome();
      await $.platform.mobile.openNotifications();

      final found = await _isNotificationVisible($, 'New grade');
      debugPrint('Notification "New grade" visible: $found');
      expect(found, isTrue, reason: 'New grade notification should appear');
    },
  );

  patrolTest(
    'step 4: background WorkManager task triggers notification',
    ($) async {
      await launchApp($);
      await loginAndSync($);

      await _grantNotificationPermission($);

      final notifService = NotificationService();
      await notifService.initialize();
      await notifService.cancelAll();
      debugPrint('STEP4: cleared all existing notifications');

      final task = BackgroundSyncTask(rescheduleOnComplete: false);
      await task.execute();
      debugPrint('STEP4: baseline sync done');

      await notifService.cancelAll();
      debugPrint('STEP4: cleared notifications from baseline sync');

      await _pushNewGrade(mockBaseUrl);
      debugPrint('STEP4: new grade pushed to mock server');

      WorkmanagerSyncScheduler.scheduleDelayedSync(
        delay: Duration.zero,
      );
      debugPrint('STEP4: expedited WorkManager task scheduled');

      await $.platform.mobile.pressHome();
      debugPrint('STEP4: app sent to background');

      debugPrint('STEP4: waiting 30s for WorkManager to fire...');
      await Future<void>.delayed(const Duration(seconds: 30));
      debugPrint('STEP4: wait complete, checking notifications');

      await $.platform.mobile.openNotifications();

      final found = await _isNotificationVisible($, 'New grade');
      debugPrint('STEP4: notification visible: $found');
      expect(
        found,
        isTrue,
        reason: 'WorkManager background sync should trigger notification',
      );
    },
  );
}

Future<void> _grantNotificationPermission(PatrolIntegrationTester $) async {
  final notifService = NotificationService();
  await notifService.initialize();

  final permissionFuture = notifService.requestPermission();

  await $.platform.mobile.grantPermissionWhenInUse();
  debugPrint('Tapped Allow on permission dialog');

  final granted = await permissionFuture;
  debugPrint('Notification permission result: $granted');
}

Future<void> _pushNewGrade(String baseUrl) async {
  await _postScenario(baseUrl, {
    'school': 'osm-wroclaw',
    'extraMarks': [
      {
        'action': 'I',
        'id': 99501,
        'mark_groups_id': 1001,
        'mark_scales_id': 1006,
        'pupil_users_id': 9001,
        'teacher_users_id': 3001,
        'mark_value': 6.0,
        'comments': null,
        'weight': 3,
        'get_date': DateTime.now().toIso8601String().substring(0, 10),
        'add_time': DateTime.now().toIso8601String(),
        'modified': 0,
        'events_id': null,
      },
    ],
  });
}

Future<void> _postScenario(String baseUrl, Map<String, dynamic> body) async {
  final client = HttpClient();
  try {
    final request = await client.postUrl(Uri.parse('$baseUrl/test/scenario'));
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode(body));
    final response = await request.close();
    await response.drain<void>();
  } finally {
    client.close();
  }
}

Future<bool> _isNotificationVisible(
  PatrolIntegrationTester $,
  String text,
) async {
  try {
    await $.platform.mobile.tapOnNotificationBySelector(
      Selector(textContains: text),
      timeout: const Duration(seconds: 5),
    );
    return true;
  } on Object catch (e) {
    debugPrint('Notification not found: $e');
    return false;
  }
}

Future<void> _resetScenarios(String baseUrl) async {
  if (baseUrl.isEmpty) return;
  final client = HttpClient();
  try {
    final request = await client.postUrl(Uri.parse('$baseUrl/test/reset'));
    request.headers.contentType = ContentType.json;
    final response = await request.close();
    await response.drain<void>();
  } finally {
    client.close();
  }
}
