import 'package:bsharp/app/account_providers.dart';
import 'package:bsharp/app/data_provider_registry.dart';
import 'package:bsharp/app/notification_preferences_provider.dart';
import 'package:bsharp/data/services/background_sync_scheduler.dart';
import 'package:bsharp/data/services/notification_service.dart';
import 'package:bsharp/data/services/sync_cache.dart';
import 'package:bsharp/data/services/sync_data_applier.dart';
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

enum SyncStatus {
  idle,
  hydrated,
  syncing,
  completed,
  failed
  ;

  bool get isBusy => this == syncing;
}

@Riverpod(keepAlive: true)
NotificationService notificationService(Ref ref) {
  return NotificationService();
}

@Riverpod(keepAlive: true)
SyncCache syncCache(Ref ref) {
  return SyncCache(ref.watch(sharedPreferencesProvider));
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

    final cache = ref.read(syncCacheProvider);
    if (state == SyncStatus.idle) {
      _hydrateFromCache(cache);
    }

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

        await Future.wait([
          provider.loadSchoolData(ref, studentId: studentId),
          provider.loadMessages(ref),
        ]);
      } else {
        await Future.wait([
          provider.loadSchoolData(ref, studentId: 1),
          provider.loadMessages(ref),
        ]);
      }

      await loadCustomEventsFromRef(ref, accountId);

      state = SyncStatus.completed;
      ref.read(lastSyncTimeProvider.notifier).value = DateTime.now();

      final changeSet = await _detectChanges();
      await _trackNewGrades(changeSet);

      await _checkUnexcusedAbsences();

      if (changeSet.isNotEmpty) {
        final service = ref.read(notificationServiceProvider);
        final prefs = ref.read(notificationPreferencesProvider);
        await service.initialize();
        await service.showChanges(changeSet, prefs);
      }

      return changeSet;
    } on Exception {
      if (state == SyncStatus.syncing) {
        state = SyncStatus.failed;
      }
      return const ChangeSet();
    }
  }

  void _hydrateFromCache(SyncCache cache) {
    final syncData = cache.loadSyncData();
    if (syncData != null) {
      applySyncData(ref, syncData);
    }

    final portalViews = {
      'bulletins': applyPortalBulletins,
      'tests': applyPortalTests,
      'homeworks': applyPortalHomeworks,
      'reprimands': applyPortalReprimands,
    };
    for (final entry in portalViews.entries) {
      final items = cache.loadPortalView(entry.key);
      if (items != null) {
        entry.value(ref, items);
      }
    }

    final markChangelog = cache.loadPortalView('changelog_mark');
    if (markChangelog != null) {
      applyPortalChangelog(ref, 'mark', markChangelog);
    }
    final attendanceChangelog = cache.loadPortalView('changelog_attendance');
    if (attendanceChangelog != null) {
      applyPortalChangelog(ref, 'attendance', attendanceChangelog);
    }

    for (final folder in ['inbox', 'sent', 'trash']) {
      final messages = cache.loadMessages(folder);
      if (messages != null) {
        applyMessages(ref, folder, messages);
      }
    }

    if (syncData != null) {
      state = SyncStatus.hydrated;
    }
  }

  Future<ChangeSet> _detectChanges() async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final previousSnapshot = await SyncSnapshot.load(prefs);

      final grades = ref.read(resolvedGradesProvider);
      final events = ref.read(resolvedEventsProvider);
      final attendances = ref.read(attendancesProvider);
      final inbox = ref.read(inboxProvider);

      final currentSnapshot = SyncSnapshot(
        markIds: grades.map((m) => m.id).toSet(),
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

  Future<void> _trackNewGrades(ChangeSet changeSet) async {
    final newIds = changeSet
        .byCategory(ChangeCategory.grades)
        .map((c) => c.entityId)
        .whereType<int>()
        .toSet();
    await ref.read(newGradeIdsProvider.notifier).addNewIds(newIds);
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
    await ref.read(providerAccountsProvider.future);
    await ref.read(activeSelectionProvider.future);
    final account = ref.read(activeAccountProvider);
    if (account == null) return null;
    return _Credentials(
      school: account.slug,
      login: account.login,
      passHash: account.passwordHash,
    );
  }

  Future<int?> _getStudentId() async {
    final selection = await ref.read(activeSelectionProvider.future);
    return selection?.studentId;
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
  final isMobile =
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
  if (!isMobile) return null;

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
