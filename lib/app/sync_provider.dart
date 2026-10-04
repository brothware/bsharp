import 'package:bsharp/app/account_providers.dart';
import 'package:bsharp/app/data_provider_registry.dart';
import 'package:bsharp/app/providers/attendance_providers.dart';
import 'package:bsharp/app/providers/custom_event_providers.dart';
import 'package:bsharp/app/providers/grades_providers.dart';
import 'package:bsharp/app/providers/messages_providers.dart';
import 'package:bsharp/app/providers/schedule_providers.dart';
import 'package:bsharp/app/reauth_provider.dart';
import 'package:bsharp/data/services/notification_service.dart';
import 'package:bsharp/data/services/sync_cache.dart';
import 'package:bsharp/data/services/sync_snapshot.dart';
import 'package:bsharp/domain/change_detection.dart';
import 'package:bsharp/domain/entities/provider_account.dart';
import 'package:bsharp/domain/entities/student.dart';
import 'package:bsharp/domain/school_data_provider.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sync_provider.g.dart';

enum SyncStatus {
  idle,
  hydrated,
  syncing,
  completed,
  failed;

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

    // Claimed before the first await so a caller sees the sync start, and
    // re-claimed after hydration, which reports the cache it restored.
    final wasIdle = state == SyncStatus.idle;
    state = SyncStatus.syncing;

    try {
      // Has to come before hydration: the cache belongs to a backend, and
      // restoring a demo account's day from the last Mobireg sync is worse
      // than showing nothing.
      await restoreProviderForActiveAccount(ref);

      if (wasIdle) {
        _hydrateFromCache(ref.read(syncCacheProvider));
      }
      state = SyncStatus.syncing;

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
          password: creds.password,
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
      ref.read(missingPupilProvider.notifier).value = false;
      ref.read(lastSyncTimeProvider.notifier).value = DateTime.now();

      final changeSet = await _detectChanges();
      await _trackNewGrades(changeSet);

      await _checkUnexcusedAbsences();

      if (changeSet.isNotEmpty) {
        ref.read(lastSyncChangesProvider.notifier).value = changeSet;
      }

      return changeSet;
    } on ReauthRequiredException {
      state = SyncStatus.failed;
      return const ChangeSet();
    } on PupilNotOnAccountException catch (error, stackTrace) {
      await _offerPupilsOnAccount(error.students);
      return _fail(error, stackTrace);
    } on Object catch (error, stackTrace) {
      return _fail(error, stackTrace);
    }
  }

  ChangeSet _fail(Object error, StackTrace stackTrace) {
    debugPrint('SyncStatusNotifier: sync failed: $error\n$stackTrace');
    if (state == SyncStatus.syncing) {
      state = SyncStatus.failed;
    }
    return const ChangeSet();
  }

  Future<void> _offerPupilsOnAccount(List<Student> students) async {
    ref.read(missingPupilProvider.notifier).value = true;
    final account = ref.read(activeAccountProvider);
    if (account == null) {
      return;
    }
    await ref
        .read(accountStorageProvider)
        .updateAccount(
          account.copyWith(
            students: [
              for (final student in students)
                AccountStudent(
                  id: student.id,
                  name: student.name,
                  surname: student.surname,
                ),
            ],
          ),
        );
    await ref.read(providerAccountsProvider.notifier).reload();
  }

  void _hydrateFromCache(SyncCache cache) {
    final provider = ref.read(activeDataProviderProvider);
    try {
      if (provider.hydrateFromCache(ref, cache)) {
        state = SyncStatus.hydrated;
      }
    } on FormatException catch (error) {
      debugPrint('SyncStatusNotifier: cache unreadable, cleared: $error');
      cache.clear();
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
      password: account.password,
    );
  }

  Future<int?> _getStudentId() async {
    final selection = await ref.read(activeSelectionProvider.future);
    return selection?.studentId;
  }

  Future<void> syncMessages() async {
    final provider = ref.read(activeDataProviderProvider);
    try {
      await provider.refreshMessages(ref);
    } on FormatException catch (error, stackTrace) {
      _failMailRefresh(error, stackTrace);
    } on MessagingException catch (error, stackTrace) {
      _failMailRefresh(error, stackTrace);
    }
  }

  void _failMailRefresh(Object error, StackTrace stackTrace) {
    debugPrint('SyncStatusNotifier: mail refresh failed: $error\n$stackTrace');
    state = SyncStatus.failed;
  }
}

class _Credentials {
  const _Credentials({
    required this.school,
    required this.login,
    required this.password,
  });

  final String school;
  final String login;
  final String password;
}

@Riverpod(keepAlive: true)
class LastSyncTime extends _$LastSyncTime {
  @override
  DateTime? build() => null;
  DateTime? get value => state;
  set value(DateTime? v) => state = v;
}

@Riverpod(keepAlive: true)
class LastSyncChanges extends _$LastSyncChanges {
  @override
  ChangeSet? build() => null;
  ChangeSet? get value => state;
  set value(ChangeSet? v) => state = v;
}
