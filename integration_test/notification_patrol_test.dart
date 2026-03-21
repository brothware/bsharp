@Tags(['patrol'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:bsharp/core/constants/app_constants.dart';
import 'package:bsharp/data/services/background_sync_task.dart';
import 'package:flutter/material.dart';
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
    'new message triggers notification and tap opens app',
    ($) async {
      await launchApp($);
      await loginAndSync($);

      final task = BackgroundSyncTask(rescheduleOnComplete: false);
      await task.execute();

      await _pushNewMessage(mockBaseUrl);

      await task.execute();

      await $.platform.mobile.pressHome();
      await $.platform.mobile.openNotifications();

      await $.platform.mobile.tapOnNotificationBySelector(
        Selector(textContains: 'New message'),
      );

      await $.pumpAndSettle();
      expect(find.byType(Scaffold), findsWidgets);
    },
  );

  patrolTest(
    'new grade triggers notification',
    ($) async {
      await launchApp($);
      await loginAndSync($);

      final task = BackgroundSyncTask(rescheduleOnComplete: false);
      await task.execute();

      await _pushNewGrade(mockBaseUrl);

      await task.execute();

      await $.platform.mobile.pressHome();
      await $.platform.mobile.openNotifications();

      await $.platform.mobile.tapOnNotificationBySelector(
        Selector(textContains: 'New grade'),
      );

      await $.pumpAndSettle();
      expect(find.byType(Scaffold), findsWidgets);
    },
  );

  patrolTest(
    'disabled notification category does not show notification',
    ($) async {
      await launchApp($);
      await loginAndSync($);

      await navigateToSettings($);
      await toggleNotification($, 'Messages');
      await goBack($);

      final task = BackgroundSyncTask(rescheduleOnComplete: false);
      await task.execute();

      await _pushNewMessage(mockBaseUrl);

      await task.execute();

      await $.platform.mobile.pressHome();
      await $.platform.mobile.openNotifications();

      final notificationFound = await _isNotificationVisible(
        $,
        'New message',
      );
      expect(notificationFound, isFalse);

      await $.platform.mobile.closeNotifications();
      await $.platform.mobile.openApp();
    },
  );

  patrolTest(
    're-enabled notification category shows notification again',
    ($) async {
      await launchApp($);
      await loginAndSync($);

      await navigateToSettings($);
      await toggleNotification($, 'Messages');
      await toggleNotification($, 'Messages');
      await goBack($);

      final task = BackgroundSyncTask(rescheduleOnComplete: false);
      await task.execute();

      await _pushNewMessage(mockBaseUrl);

      await task.execute();

      await $.platform.mobile.pressHome();
      await $.platform.mobile.openNotifications();

      await $.platform.mobile.tapOnNotificationBySelector(
        Selector(textContains: 'New message'),
      );

      await $.pumpAndSettle();
      expect(find.byType(Scaffold), findsWidgets);
    },
  );
}

Future<void> _pushNewMessage(String baseUrl) async {
  await _postScenario(baseUrl, {
    'school': 'osm-wroclaw',
    'extraInbox': [
      {
        'id': 99001,
        'subject': 'Patrol test message',
        'date': DateTime.now().toIso8601String(),
        'content': 'This message was pushed during a patrol test',
        'read_at': null,
        'stared': false,
        'author': {'name': 'Jan Nowak'},
        'recipients': [
          {
            'name': 'Tomasz Śliwa',
            'roleName': 'Rodzic',
            'read_at': null,
          },
        ],
      },
    ],
  });
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

Future<bool> _isNotificationVisible(
  PatrolIntegrationTester $,
  String text,
) async {
  try {
    await $.platform.mobile.tapOnNotificationBySelector(
      Selector(textContains: text),
      timeout: const Duration(seconds: 3),
    );
    return true;
  } on Object {
    return false;
  }
}
