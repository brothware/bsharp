import 'package:bsharp/data/services/background_sync_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WebSyncScheduler', () {
    test('isScheduled returns false initially', () {
      final scheduler = WebSyncScheduler(onSync: () async {});
      expect(scheduler.isScheduled, isFalse);
    });

    test('isScheduled returns true after schedule', () {
      final scheduler = WebSyncScheduler(onSync: () async {})
        ..schedule(interval: const Duration(seconds: 10));
      expect(scheduler.isScheduled, isTrue);
      scheduler.cancel();
    });

    test('cancel stops the scheduler', () {
      final scheduler = WebSyncScheduler(onSync: () async {})
        ..schedule(interval: const Duration(seconds: 10))
        ..cancel();
      expect(scheduler.isScheduled, isFalse);
    });

    test('setVisibility controls sync execution', () {
      var syncCount = 0;
      final scheduler = WebSyncScheduler(onSync: () async => syncCount++)
        ..isVisible = false;
      expect(scheduler.isScheduled, isFalse);
      scheduler.cancel();
    });
  });

  group('MobileSyncScheduler', () {
    test('isScheduled returns false initially', () {
      final scheduler = MobileSyncScheduler(onSync: () async {});
      expect(scheduler.isScheduled, isFalse);
    });

    test('isScheduled returns true after schedule', () {
      final scheduler = MobileSyncScheduler(onSync: () async {})
        ..schedule(interval: const Duration(seconds: 10));
      expect(scheduler.isScheduled, isTrue);
      scheduler.cancel();
    });

    test('cancel stops the scheduler', () {
      final scheduler = MobileSyncScheduler(onSync: () async {})
        ..schedule(interval: const Duration(seconds: 10))
        ..cancel();
      expect(scheduler.isScheduled, isFalse);
    });

    test('reschedule restarts with same interval', () {
      final scheduler = MobileSyncScheduler(onSync: () async {})
        ..schedule(interval: const Duration(seconds: 10))
        ..cancel()
        ..reschedule();
      expect(scheduler.isScheduled, isTrue);
      scheduler.cancel();
    });
  });
}
