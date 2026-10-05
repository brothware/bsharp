import 'package:bsharp/app/account_providers.dart';
import 'package:bsharp/app/data_provider_registry.dart';
import 'package:bsharp/app/providers/attendance_providers.dart';
import 'package:bsharp/app/providers/custom_event_providers.dart';
import 'package:bsharp/app/providers/grades_providers.dart';
import 'package:bsharp/app/providers/messages_providers.dart';
import 'package:bsharp/app/providers/schedule_providers.dart';
import 'package:bsharp/app/reauth_provider.dart';
import 'package:bsharp/app/sync_health_provider.dart';
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
  SyncStatus build() {
    ref.listen(activeSelectionProvider, (previous, next) {
      final before = previous?.value;
      final after = next.value;
      final isSwitched =
          before != null &&
          (after?.accountId != before.accountId ||
              after?.studentId != before.studentId);
      if (isSwitched) {
        ref.read(syncHealthProvider.notifier).reset();
        ref.read(lastSyncTimeProvider.notifier).value = null;
      }
    });
    return SyncStatus.idle;
  }

  SyncStatus get value => state;
  set value(SyncStatus v) => state = v;

  Future<ChangeSet> sync() async {
    if (state == SyncStatus.syncing) return const ChangeSet();

    final wasIdle = state == SyncStatus.idle;
    state = SyncStatus.syncing;

    try {
      await restoreProviderForActiveAccount(ref);

      final selectedStudentId = await _getStudentId();
      if (wasIdle && selectedStudentId != null) {
        _hydrateFromCache(
          ref.read(syncCacheProvider),
          studentId: selectedStudentId,
        );
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

        await provider.loadSchoolData(ref, studentId: studentId);
      } else {
        await provider.loadSchoolData(ref, studentId: 1);
      }
      await _loadMail(provider, () => provider.loadMessages(ref));

      await loadCustomEventsFromRef(ref, accountId);

      ref.read(missingPupilProvider.notifier).value = false;
      ref.read(lastSyncTimeProvider.notifier).value = DateTime.now();

      final ChangeSet changeSet;
      try {
        changeSet = await _detectChanges();
      } on Object catch (error, stackTrace) {
        debugPrint(
          'SyncStatusNotifier: data applied but change detection failed: '
          '$error\n$stackTrace',
        );
        state = SyncStatus.failed;
        return const ChangeSet();
      }
      state = SyncStatus.completed;
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

  void _hydrateFromCache(SyncCache cache, {required int studentId}) {
    final provider = ref.read(activeDataProviderProvider);
    try {
      if (provider.hydrateFromCache(ref, cache, studentId: studentId)) {
        state = SyncStatus.hydrated;
      }
    } on FormatException catch (error) {
      debugPrint('SyncStatusNotifier: cache unreadable, cleared: $error');
      cache.clear();
    }
  }

  Future<ChangeSet> _detectChanges() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final previousSnapshot = await SyncSnapshot.load(prefs);

    final grades = ref.read(resolvedGradesProvider);
    final events = ref.read(resolvedEventsProvider);
    final attendances = ref.read(attendancesProvider);
    final isMailStale = ref
        .read(syncHealthProvider)
        .isStale(DataProviderCapability.messages);
    final inbox = ref.read(inboxProvider);

    final currentSnapshot = SyncSnapshot(
      markIds: grades.map((m) => m.id).toSet(),
      eventIds: events.map((e) => e.id).toSet(),
      attendanceIds: attendances.map((a) => a.id).toSet(),
      inboxMessageIds: isMailStale
          ? previousSnapshot?.inboxMessageIds ?? const {}
          : inbox.map((m) => m.id).toSet(),
      isInboxBaselineKnown:
          !isMailStale || (previousSnapshot?.isInboxBaselineKnown ?? false),
    );

    final changeSet = currentSnapshot.diff(previousSnapshot);
    await currentSnapshot.save(prefs);
    return changeSet;
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

  Future<bool> syncMessages() async {
    final provider = ref.read(activeDataProviderProvider);
    final isStale = ref
        .read(syncHealthProvider)
        .isStale(DataProviderCapability.messages);
    return _loadMail(provider, () async {
      if (isStale) {
        return provider.loadMessages(ref);
      }
      await provider.refreshMessages(ref);
      return true;
    });
  }

  Future<bool> _loadMail(
    SchoolDataProvider provider,
    Future<bool> Function() load,
  ) async {
    final health = ref.read(syncHealthProvider.notifier);
    try {
      final isLoaded = await load();
      if (isLoaded) {
        _recordSynced(provider.areasCovered(SyncOperation.mail));
      }
      return isLoaded;
    } on Object catch (error, stackTrace) {
      final staleAreas = provider.staleAreasAfter(
        error,
        during: SyncOperation.mail,
      );
      if (staleAreas.isEmpty) {
        Error.throwWithStackTrace(error, stackTrace);
      }
      debugPrint(
        'SyncStatusNotifier: mail unavailable, '
        '${staleAreas.map((area) => area.name).join(', ')} not synced: '
        '$error\n$stackTrace',
      );
      health.markStale(
        staleAreas,
        knownSyncedAt: _persistedSyncTimes(staleAreas),
      );
      return false;
    }
  }

  String? _healthScope() {
    final selection = ref.read(activeSelectionProvider).value;
    if (selection == null) {
      return null;
    }
    return '${selection.accountId}_${selection.studentId}';
  }

  void _recordSynced(Set<DataProviderCapability> areas) {
    final at = DateTime.now();
    ref.read(syncHealthProvider.notifier).markSynced(areas, at);
    final scope = _healthScope();
    if (scope == null) {
      return;
    }
    final cache = ref.read(syncCacheProvider);
    for (final area in areas) {
      cache.saveAreaSyncedAt(scope, area.name, at);
    }
  }

  Map<DataProviderCapability, DateTime> _persistedSyncTimes(
    Set<DataProviderCapability> areas,
  ) {
    final scope = _healthScope();
    if (scope == null) {
      return const {};
    }
    final cache = ref.read(syncCacheProvider);
    return {
      for (final area in areas) area: ?cache.loadAreaSyncedAt(scope, area.name),
    };
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
