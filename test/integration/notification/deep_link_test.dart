@TestOn('vm')
library;

import 'package:bsharp/data/services/notification_service.dart';
import 'package:bsharp/domain/change_detection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationPayload', () {
    test('grade notification has correct route', () {
      const payload = NotificationPayload(
        accountId: 'acc-1',
        studentId: 6541,
        route: '/grades',
      );

      final json = payload.toJson();
      final restored = NotificationPayload.fromJson(json);

      expect(restored.accountId, 'acc-1');
      expect(restored.studentId, 6541);
      expect(restored.route, '/grades');
    });

    test('message notification has correct route', () {
      const payload = NotificationPayload(
        accountId: 'acc-1',
        studentId: 6541,
        route: '/messages',
      );

      final json = payload.toJson();
      final restored = NotificationPayload.fromJson(json);

      expect(restored.route, '/messages');
    });

    test('payload serialization round-trips correctly for all categories', () {
      final routes = {
        ChangeCategory.grades: '/grades',
        ChangeCategory.messages: '/messages',
        ChangeCategory.schedule: '/schedule',
        ChangeCategory.attendance: '/attendance',
        ChangeCategory.homework: '/homework',
        ChangeCategory.notes: '/notes',
      };

      for (final entry in routes.entries) {
        final payload = NotificationPayload(
          accountId: 'acc-2',
          studentId: 7001,
          route: entry.value,
        );

        final restored = NotificationPayload.fromJson(payload.toJson());
        expect(
          restored.route,
          entry.value,
          reason: '${entry.key} route mismatch',
        );
        expect(restored.accountId, 'acc-2');
        expect(restored.studentId, 7001);
      }
    });
  });
}
