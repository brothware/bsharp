import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/data_provider_registry.dart';
import 'package:bsharp/app/notification_preferences_provider.dart';
import 'package:bsharp/data/services/background_sync_scheduler.dart';
import 'package:bsharp/data/services/notification_service.dart';
import 'package:bsharp/data/services/sync_snapshot.dart';
import 'package:bsharp/domain/change_detection.dart';
import 'package:bsharp/presentation/attendance/providers/attendance_providers.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:bsharp/presentation/grades/providers/grades_providers.dart';
import 'package:bsharp/presentation/messages/providers/messages_providers.dart';
import 'package:bsharp/presentation/schedule/providers/custom_event_providers.dart';
import 'package:bsharp/presentation/schedule/providers/schedule_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sync_provider.g.dart';

enum SyncStatus { idle, syncing, completed, failed }

@Riverpod(keepAlive: true)
NotificationService notificationService(Ref ref) {
  return NotificationService();
}

final syncStatusProvider = NotifierProvider<SyncStatusNotifier, SyncStatus>(
  SyncStatusNotifier.new,
);

class SyncStatusNotifier extends Notifier<SyncStatus> {
  @override
  SyncStatus build() => SyncStatus.idle;
  SyncStatus get value => state;
  set value(SyncStatus v) => state = v;

  Future<ChangeSet> sync() async {
    if (state == SyncStatus.syncing) return const ChangeSet();
    state = SyncStatus.syncing;
    try {
      final provider = ref.read(activeDataProviderProvider);
      var accountId = 1;

      if (provider.requiresCredentials) {
        final creds = await _getCredentials();
        if (creds == null) {
          state = SyncStatus.failed;
          return const ChangeSet();
        }

        final studentId = await _getStudentId();
        if (studentId == null) {
          state = SyncStatus.failed;
          return const ChangeSet();
        }

        accountId = studentId;

        await provider.authenticate(
          school: creds.school,
          login: creds.login,
          passwordHash: creds.passHash,
        );

        await provider.loadSchoolData(ref, studentId: studentId);
        await provider.loadMessages(ref);
      } else {
        await provider.loadSchoolData(ref, studentId: 1);
        await provider.loadMessages(ref);
      }

      await loadCustomEventsFromRef(ref, accountId);

      state = SyncStatus.completed;
      ref.read(lastSyncTimeProvider.notifier).value = DateTime.now();

      final changeSet = await _detectChanges();

      await _checkUnexcusedAbsences();

      if (changeSet.isNotEmpty) {
        final service = ref.read(notificationServiceProvider);
        final prefs = ref.read(notificationPreferencesProvider);
        await service.initialize();
        await service.showChanges(changeSet, prefs);
      }

      return changeSet;
    } on Exception {
      state = SyncStatus.failed;
      return const ChangeSet();
    }
  }

  Future<ChangeSet> _detectChanges() async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final previousSnapshot = await SyncSnapshot.load(prefs);

      final marks = ref.read(marksProvider);
      final events = ref.read(eventsProvider);
      final attendances = ref.read(attendancesProvider);
      final inbox = ref.read(inboxProvider);

      final currentSnapshot = SyncSnapshot(
        markIds: marks.map((m) => m.id).toSet(),
        eventIds: events.map((e) => e.id).toSet(),
        attendanceIds: attendances.map((a) => a.id).toSet(),
        inboxMessageIds: inbox.map((m) => m.id).toSet(),
      );

      final changeSet = currentSnapshot.diff(previousSnapshot);
      await currentSnapshot.save(prefs);
      return changeSet;
    } on Object {
      return const ChangeSet();
    }
  }

  void markCompleted() {
    state = SyncStatus.completed;
    ref.read(lastSyncTimeProvider.notifier).value = DateTime.now();
  }

  Future<void> _checkUnexcusedAbsences() async {
    final stale = ref.read(staleUnexcusedAbsencesProvider);
    final service = ref.read(notificationServiceProvider);
    await service.initialize();
    await service.showUnexcusedAbsenceAlert(stale.length);
  }

  Future<void> forceFullSync() async {
    await sync();
  }

  void reset() => state = SyncStatus.idle;

  Future<_Credentials?> _getCredentials() async {
    final storage = ref.read(credentialStorageProvider);
    final results = await Future.wait([
      storage.getSchool(),
      storage.getLogin(),
      storage.getPasswordHash(),
    ]);
    final school = results[0];
    final login = results[1];
    final passHash = results[2];

    if (school == null || login == null || passHash == null) return null;
    return _Credentials(school: school, login: login, passHash: passHash);
  }

  Future<int?> _getStudentId() async {
    final storage = ref.read(credentialStorageProvider);
    return storage.getSelectedStudentId();
  }

  Future<void> syncMessages() async {
    final provider = ref.read(activeDataProviderProvider);
    await provider.refreshMessages(ref);
  }
}

class _Credentials {
  const _Credentials({
    required this.school,
    required this.login,
    required this.passHash,
  });

  final String school;
  final String login;
  final String passHash;
}

@Riverpod(keepAlive: true)
class LastSyncTime extends _$LastSyncTime {
  @override
  DateTime? build() => null;
  DateTime? get value => state;
  set value(DateTime? v) => state = v;
}

@Riverpod(keepAlive: true)
BackgroundSyncScheduler? backgroundSyncScheduler(Ref ref) {
  if (kIsWeb) return null;

  final scheduler = WorkmanagerSyncScheduler();
  final interval = ref.watch(syncIntervalProvider);
  scheduler.schedule(interval: interval);

  ref.onDispose(scheduler.cancel);
  return scheduler;
}

@Riverpod(keepAlive: true)
Duration syncInterval(Ref ref) {
  final prefs = ref.watch(notificationPreferencesProvider);
  return Duration(minutes: prefs.syncIntervalMinutes);
}
