@Tags(['patrol'])
library;

import 'package:bsharp/data/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'helpers/patrol_helpers.dart';

void main() {
  patrolTest('FCM message notification appears and tap opens app', ($) async {
    await launchApp($);
    await loginAndSync($);

    final service = NotificationService();
    await service.initialize();

    await service.showFcmNotification(
      const LocalFcmNotification(
        title: 'New message',
        body: 'From: Jan Nowak',
        channelId: 'messages',
        channelName: 'Messages',
        channelDescription: 'New messages',
        route: '/messages',
      ),
    );

    await $.platform.mobile.pressHome();
    await $.platform.mobile.openNotifications();

    await $.platform.mobile.tapOnNotificationBySelector(
      Selector(textContains: 'New message'),
    );

    await $.pumpAndSettle();
    expect(find.byType(Scaffold), findsWidgets);
  });
}
