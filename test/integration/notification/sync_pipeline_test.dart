@TestOn('vm')
library;

import 'package:bsharp/data/services/sync_snapshot.dart';
import 'package:bsharp/domain/change_detection.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.en);
  });

  group('Sync pipeline change detection', () {
    test('first sync with null previous produces no changes', () {
      const snapshot = SyncSnapshot(markIds: {1, 2}, eventIds: {10});
      final changes = snapshot.diff(null);
      expect(changes.isEmpty, isTrue);
    });

    test('second sync with new mark produces grade change', () {
      const previous = SyncSnapshot(markIds: {1, 2});
      const current = SyncSnapshot(markIds: {1, 2, 3});
      final changes = current.diff(previous);
      expect(changes.isNotEmpty, isTrue);
      expect(changes.byCategory(ChangeCategory.grades).length, 1);
      expect(changes.byCategory(ChangeCategory.grades).first.entityId, 3);
    });

    test('multiple categories change correctly', () {
      const previous = SyncSnapshot(
        markIds: {1},
        inboxMessageIds: {10},
        eventIds: {100},
      );
      const current = SyncSnapshot(
        markIds: {1, 2},
        inboxMessageIds: {10, 11, 12},
        eventIds: {100, 101},
      );
      final changes = current.diff(previous);
      expect(changes.countByCategory(ChangeCategory.grades), 1);
      expect(changes.countByCategory(ChangeCategory.messages), 2);
      expect(changes.countByCategory(ChangeCategory.schedule), 1);
    });

    test('ChangeSet copyWith attaches account context', () {
      const changes = ChangeSet(
        changes: [
          ChangeItem(category: ChangeCategory.grades, title: 'G'),
        ],
      );
      final withContext = changes.copyWith(accountId: 'acc-1', studentId: 42);
      expect(withContext.accountId, 'acc-1');
      expect(withContext.studentId, 42);
      expect(withContext.changes.length, 1);
    });
  });
}
