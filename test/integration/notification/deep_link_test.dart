@TestOn('vm')
library;

import 'package:bsharp/data/services/notification_service.dart';
import 'package:bsharp/domain/change_detection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationPayload', () {
    test('grade notification keeps its category', () {
      const payload = NotificationPayload(
        accountId: 'acc-1',
        studentId: 6541,
        category: ChangeCategory.grades,
      );

      final json = payload.toJson();
      final restored = NotificationPayload.fromJson(json);

      expect(restored.accountId, 'acc-1');
      expect(restored.studentId, 6541);
      expect(restored.category, ChangeCategory.grades);
    });

    test('message notification keeps its category', () {
      const payload = NotificationPayload(
        accountId: 'acc-1',
        studentId: 6541,
        category: ChangeCategory.messages,
      );

      final json = payload.toJson();
      final restored = NotificationPayload.fromJson(json);

      expect(restored.category, ChangeCategory.messages);
    });

    test('payload serialization round-trips correctly for all categories', () {
      for (final category in ChangeCategory.values) {
        final payload = NotificationPayload(
          accountId: 'acc-2',
          studentId: 7001,
          category: category,
        );

        final restored = NotificationPayload.fromJson(payload.toJson());
        expect(
          restored.category,
          category,
          reason: '$category did not survive the round trip',
        );
        expect(restored.accountId, 'acc-2');
        expect(restored.studentId, 7001);
      }
    });
  });
}
