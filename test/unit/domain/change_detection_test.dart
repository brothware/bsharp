import 'package:flutter_test/flutter_test.dart';
import 'package:bsharp/domain/change_detection.dart';

void main() {
  group('ChangeSet', () {
    test('isEmpty returns true for no changes', () {
      const cs = ChangeSet();
      expect(cs.isEmpty, isTrue);
      expect(cs.isNotEmpty, isFalse);
      expect(cs.totalCount, 0);
    });

    test('totalCount returns correct count', () {
      final cs = ChangeSet(changes: [
        const ChangeItem(category: ChangeCategory.grades, title: 'New grade'),
        const ChangeItem(category: ChangeCategory.messages, title: 'New message'),
      ]);
      expect(cs.totalCount, 2);
      expect(cs.isNotEmpty, isTrue);
    });

    test('byCategory filters correctly', () {
      final cs = ChangeSet(changes: [
        const ChangeItem(category: ChangeCategory.grades, title: 'Grade 1'),
        const ChangeItem(category: ChangeCategory.grades, title: 'Grade 2'),
        const ChangeItem(category: ChangeCategory.messages, title: 'Message'),
      ]);

      expect(cs.byCategory(ChangeCategory.grades).length, 2);
      expect(cs.byCategory(ChangeCategory.messages).length, 1);
      expect(cs.byCategory(ChangeCategory.schedule).length, 0);
    });

    test('countByCategory returns correct count', () {
      final cs = ChangeSet(changes: [
        const ChangeItem(category: ChangeCategory.grades, title: 'A'),
        const ChangeItem(category: ChangeCategory.grades, title: 'B'),
        const ChangeItem(category: ChangeCategory.homework, title: 'C'),
      ]);

      expect(cs.countByCategory(ChangeCategory.grades), 2);
      expect(cs.countByCategory(ChangeCategory.homework), 1);
      expect(cs.countByCategory(ChangeCategory.attendance), 0);
    });

    test('merge combines two change sets', () {
      final cs1 = ChangeSet(changes: [
        const ChangeItem(category: ChangeCategory.grades, title: 'A'),
      ]);
      final cs2 = ChangeSet(changes: [
        const ChangeItem(category: ChangeCategory.messages, title: 'B'),
      ]);

      final merged = cs1.merge(cs2);
      expect(merged.totalCount, 2);
    });

    test('grouped returns map of changes by category', () {
      final cs = ChangeSet(changes: [
        const ChangeItem(category: ChangeCategory.grades, title: 'A'),
        const ChangeItem(category: ChangeCategory.grades, title: 'B'),
        const ChangeItem(category: ChangeCategory.messages, title: 'C'),
      ]);

      final grouped = cs.grouped;
      expect(grouped.length, 2);
      expect(grouped[ChangeCategory.grades]!.length, 2);
      expect(grouped[ChangeCategory.messages]!.length, 1);
    });

    test('summary produces English text', () {
      final cs = ChangeSet(changes: [
        const ChangeItem(category: ChangeCategory.grades, title: 'A'),
        const ChangeItem(category: ChangeCategory.messages, title: 'B'),
      ]);

      final summary = cs.summary(
        gradesLabel: (n) => '$n grades',
        messagesLabel: (n) => '$n messages',
        scheduleLabel: (n) => '$n schedule changes',
        attendanceLabel: (n) => '$n attendance records',
        homeworkLabel: (n) => '$n homework tasks',
        notesLabel: (n) => '$n notes',
        noChanges: 'No changes',
        newChanges: (s) => 'New: $s',
      );
      expect(summary, contains('1 grades'));
      expect(summary, contains('1 messages'));
    });

    test('summary returns "No changes" when empty', () {
      const cs = ChangeSet();
      final summary = cs.summary(
        gradesLabel: (n) => '$n grades',
        messagesLabel: (n) => '$n messages',
        scheduleLabel: (n) => '$n schedule changes',
        attendanceLabel: (n) => '$n attendance records',
        homeworkLabel: (n) => '$n homework tasks',
        notesLabel: (n) => '$n notes',
        noChanges: 'No changes',
        newChanges: (s) => 'New: $s',
      );
      expect(summary, 'No changes');
    });
  });

  group('BackoffStrategy', () {
    test('returns base interval for zero failures', () {
      const backoff = BackoffStrategy(
        baseInterval: Duration(minutes: 30),
      );
      expect(backoff.intervalAfterFailures(0), const Duration(minutes: 30));
    });

    test('doubles interval after 1 failure', () {
      const backoff = BackoffStrategy(
        baseInterval: Duration(minutes: 30),
        multiplier: 2.0,
      );
      expect(backoff.intervalAfterFailures(1), const Duration(minutes: 60));
    });

    test('caps at maxInterval', () {
      const backoff = BackoffStrategy(
        baseInterval: Duration(minutes: 30),
        maxInterval: Duration(hours: 4),
        multiplier: 2.0,
      );

      expect(backoff.intervalAfterFailures(10), const Duration(hours: 4));
    });

    test('progressive backoff with multiple failures', () {
      const backoff = BackoffStrategy(
        baseInterval: Duration(minutes: 15),
        maxInterval: Duration(hours: 4),
        multiplier: 2.0,
      );

      expect(backoff.intervalAfterFailures(0), const Duration(minutes: 15));
      expect(backoff.intervalAfterFailures(1), const Duration(minutes: 30));
      expect(backoff.intervalAfterFailures(2), const Duration(minutes: 60));
      expect(backoff.intervalAfterFailures(3), const Duration(minutes: 120));
      expect(backoff.intervalAfterFailures(4), const Duration(hours: 4));
    });

    test('negative failures return base interval', () {
      const backoff = BackoffStrategy(
        baseInterval: Duration(minutes: 30),
      );
      expect(backoff.intervalAfterFailures(-1), const Duration(minutes: 30));
    });
  });

  group('ChangeItem', () {
    test('stores all fields', () {
      const item = ChangeItem(
        category: ChangeCategory.grades,
        title: 'New grade: 5',
        subtitle: 'Mathematics',
        entityId: 42,
      );

      expect(item.category, ChangeCategory.grades);
      expect(item.title, 'New grade: 5');
      expect(item.subtitle, 'Mathematics');
      expect(item.entityId, 42);
    });
  });
}
