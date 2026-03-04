import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/data_provider_registry.dart';
import 'package:bsharp/app/notification_preferences_provider.dart';
import 'package:bsharp/data/services/background_sync_scheduler.dart';
import 'package:bsharp/data/services/notification_service.dart';
import 'package:bsharp/domain/change_detection.dart';
import 'package:bsharp/presentation/attendance/providers/attendance_providers.dart';

enum SyncStatus { idle, syncing, completed, failed }

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final syncStatusProvider = NotifierProvider<SyncStatusNotifier, SyncStatus>(
  SyncStatusNotifier.new,
);

class SyncStatusNotifier extends Notifier<SyncStatus> {
  @override
  SyncStatus build() => SyncStatus.idle;

  Future<ChangeSet> sync() async {
    if (state == SyncStatus.syncing) return const ChangeSet();
    state = SyncStatus.syncing;
    try {
      final provider = ref.read(activeDataProviderProvider);

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

      state = SyncStatus.completed;
      ref.read(lastSyncTimeProvider.notifier).state = DateTime.now();

      await _checkUnexcusedAbsences();

      return const ChangeSet();
    } on Exception {
      state = SyncStatus.failed;
      return const ChangeSet();
    }
  }

  void markCompleted() {
    state = SyncStatus.completed;
    ref.read(lastSyncTimeProvider.notifier).state = DateTime.now();
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

final lastSyncTimeProvider = StateProvider<DateTime?>((ref) => null);

final backgroundSyncSchedulerProvider = Provider<BackgroundSyncScheduler?>(
  (ref) => null,
);

final syncIntervalProvider = Provider<Duration>((ref) {
  final prefs = ref.watch(notificationPreferencesProvider);
  return Duration(minutes: prefs.syncIntervalMinutes);
});
