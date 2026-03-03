import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/child_provider.dart';
import 'package:bsharp/app/notification_preferences_provider.dart';
import 'package:bsharp/core/network/api_client_factory.dart';
import 'package:bsharp/data/data_sources/remote/auth_service.dart';
import 'package:bsharp/data/data_sources/remote/mobile_sync_data_source.dart';
import 'package:bsharp/data/data_sources/remote/poczta_data_source.dart';
import 'package:bsharp/data/data_sources/remote/portal_data_source.dart';
import 'package:bsharp/data/services/background_sync_scheduler.dart';
import 'package:bsharp/data/services/notification_service.dart';
import 'package:bsharp/data/services/sync_data_parser.dart';
import 'package:bsharp/domain/change_detection.dart';
import 'package:bsharp/domain/entities/poczta.dart';
import 'package:bsharp/domain/entities/portal.dart';
import 'package:bsharp/presentation/attendance/providers/attendance_providers.dart';
import 'package:bsharp/presentation/grades/providers/grades_providers.dart';
import 'package:bsharp/presentation/messages/providers/messages_providers.dart';
import 'package:bsharp/presentation/more/providers/more_providers.dart';
import 'package:bsharp/presentation/schedule/providers/schedule_providers.dart';

enum SyncStatus { idle, syncing, completed, failed }

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final syncStatusProvider =
    NotifierProvider<SyncStatusNotifier, SyncStatus>(SyncStatusNotifier.new);

class SyncStatusNotifier extends Notifier<SyncStatus> {
  @override
  SyncStatus build() => SyncStatus.idle;

  Future<ChangeSet> sync() async {
    if (state == SyncStatus.syncing) return const ChangeSet();
    state = SyncStatus.syncing;
    try {
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

      final factory = ApiClientFactory(
        school: creds.school,
        parentLogin: creds.login,
        parentPassHash: creds.passHash,
      );

      final syncDataSource =
          MobileSyncDataSource(client: factory.createMobileSyncClient());

      final now = DateTime.now();
      final startDate = now
          .subtract(const Duration(days: 100))
          .toIso8601String()
          .substring(0, 10);
      final endDate =
          now.add(const Duration(days: 100)).toIso8601String().substring(0, 10);

      final result = await syncDataSource.fullSync(
        studentId: studentId,
        startDate: startDate,
        endDate: endDate,
      );

      final syncOk = result.when(
        success: (data) {
          _applyData(data);
          return true;
        },
        failure: (_) => false,
      );

      if (!syncOk) {
        state = SyncStatus.failed;
        return const ChangeSet();
      }

      await _syncMessages(factory, creds, studentId);

      state = SyncStatus.completed;
      ref.read(lastSyncTimeProvider.notifier).state = DateTime.now();

      await _checkUnexcusedAbsences();

      return const ChangeSet();
    } on Exception {
      state = SyncStatus.failed;
      return const ChangeSet();
    }
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

  Future<void> _syncMessages(
    ApiClientFactory factory,
    _Credentials creds,
    int pupilId,
  ) async {
    try {
      final authService =
          AuthService(webLoginClient: factory.createWebLoginClient());
      final tokenResult = await authService.obtainPortalToken(
        login: creds.login,
        passwordHash: creds.passHash,
      );

      final token = tokenResult.when(
        success: (t) => t,
        failure: (_) => null,
      );
      if (token == null) return;

      final portalDs =
          PortalDataSource(client: factory.createPortalClient());
      final userResult = await portalDs.getView(
        school: creds.school,
        token: token,
        view: 'users',
        params: {},
      );

      final messagesToken = userResult.when(
        success: (data) => data['messagesToken'] as String?,
        failure: (_) => null,
      );

      await _syncPortalData(portalDs, creds, token, pupilId);

      if (messagesToken == null) return;

      final pocztaDs =
          PocztaDataSource(client: factory.createPocztaClient());
      final sessionResult = await pocztaDs.establishSession(
        school: creds.school,
        messagesToken: messagesToken,
      );

      final sessionOk = sessionResult.when(
        success: (_) => true,
        failure: (_) => false,
      );
      if (!sessionOk) return;

      ref.read(pocztaDataSourceProvider.notifier).state = pocztaDs;

      final inboxResult = await pocztaDs.getInbox();
      inboxResult.when(
        success: (data) {
          final messages = _parseMessages(data);
          ref.read(inboxProvider.notifier).state = messages;
        },
        failure: (_) {},
      );

      final sentResult = await pocztaDs.getSent();
      sentResult.when(
        success: (data) {
          final messages = _parseMessages(data);
          ref.read(sentProvider.notifier).state = messages;
        },
        failure: (_) {},
      );

      final trashResult = await pocztaDs.getTrash();
      trashResult.when(
        success: (data) {
          final messages = _parseMessages(data);
          ref.read(trashProvider.notifier).state = messages;
        },
        failure: (_) {},
      );
    } on Exception {
      // Message sync is best-effort; don't fail the main sync
    }
  }

  Future<void> syncMessages() async {
    final pocztaDs = ref.read(pocztaDataSourceProvider);
    if (pocztaDs == null || !pocztaDs.hasSession) return;

    final results = await Future.wait([
      pocztaDs.getInbox(),
      pocztaDs.getSent(),
      pocztaDs.getTrash(),
    ]);

    results[0].when(
      success: (data) {
        ref.read(inboxProvider.notifier).state = _parseMessages(data);
      },
      failure: (_) {},
    );
    results[1].when(
      success: (data) {
        ref.read(sentProvider.notifier).state = _parseMessages(data);
      },
      failure: (_) {},
    );
    results[2].when(
      success: (data) {
        ref.read(trashProvider.notifier).state = _parseMessages(data);
      },
      failure: (_) {},
    );
  }

  Future<void> _syncPortalData(
    PortalDataSource portalDs,
    _Credentials creds,
    String token,
    int pupilId,
  ) async {
    final now = DateTime.now();
    final schoolYearStart = now.month >= 9
        ? DateTime(now.year, 9, 1)
        : DateTime(now.year - 1, 9, 1);
    final schoolYearEnd = DateTime(schoolYearStart.year + 1, 8, 31);
    final dateFrom = schoolYearStart.toIso8601String().substring(0, 10);
    final dateTo = schoolYearEnd.toIso8601String().substring(0, 10);
    final pupilIdStr = pupilId.toString();

    final params = {
      'pupilId': pupilIdStr,
      'dateFrom': dateFrom,
      'dateTo': dateTo,
    };

    await _fetchPortalView(
      portalDs, creds, token, 'bulletins', params,
      (items) => ref.read(bulletinsProvider.notifier).state =
          _parseBulletins(items),
    );

    final changelogParams = {
      ...params,
      'limit': '100',
      'offset': '0',
    };
    await _fetchPortalView(
      portalDs, creds, null, 'changelog',
      {...changelogParams, 'type': 'mark'},
      (items) => ref.read(gradeChangelogProvider.notifier).state =
          _parseChangelog(items),
    );

    await _fetchPortalView(
      portalDs, creds, null, 'changelog',
      {...changelogParams, 'type': 'attendance'},
      (items) => ref.read(attendanceChangelogProvider.notifier).state =
          _parseChangelog(items),
    );

    await _fetchPortalView(
      portalDs, creds, null, 'reprimands', params,
      (items) => ref.read(reprimandsProvider.notifier).state =
          _parseReprimands(items),
    );

    await _fetchPortalView(
      portalDs, creds, null, 'tests', params,
      (items) => ref.read(testsProvider.notifier).state = _parseTests(items),
    );

    await _fetchPortalView(
      portalDs, creds, null, 'homeworks', params,
      (items) => ref.read(homeworksProvider.notifier).state =
          _parseHomeworks(items),
    );
  }

  Future<void> _fetchPortalView(
    PortalDataSource portalDs,
    _Credentials creds,
    String? token,
    String view,
    Map<String, String> params,
    void Function(List<dynamic> items) onSuccess,
  ) async {
    final viewToken = token ?? await _refreshToken(creds);
    if (viewToken == null) return;

    final result = await portalDs.getView(
      school: creds.school,
      token: viewToken,
      view: view,
      params: params,
    );
    result.when(
      success: (data) {
        final items = data['items'] as List<dynamic>? ?? [];
        onSuccess(items);
      },
      failure: (_) {},
    );
  }

  Future<String?> _refreshToken(_Credentials creds) async {
    final authService =
        AuthService(webLoginClient: ApiClientFactory(
      school: creds.school,
      parentLogin: creds.login,
      parentPassHash: creds.passHash,
    ).createWebLoginClient());
    final result = await authService.obtainPortalToken(
      login: creds.login,
      passwordHash: creds.passHash,
    );
    return result.when(success: (t) => t, failure: (_) => null);
  }

  List<PocztaMessage> _parseMessages(List<dynamic> data) =>
      parsePocztaMessages(data);

  List<PortalBulletin> _parseBulletins(List<dynamic> data) {
    final result = <PortalBulletin>[];
    for (final item in data) {
      if (item is! Map<String, dynamic>) continue;
      try {
        result.add(PortalBulletin(
          id: item['id'] as int,
          title: (item['title'] ?? '') as String,
          content: '',
          date: (item['dateTime'] ?? '') as String,
          author: (item['author'] ?? '') as String,
          isRead: item['read'] != null,
        ));
      } on Object {
        continue;
      }
    }
    return result;
  }

  List<PortalChangelog> _parseChangelog(List<dynamic> data) {
    final result = <PortalChangelog>[];
    for (final item in data) {
      if (item is! Map<String, dynamic>) continue;
      try {
        result.add(PortalChangelog(
          type: (item['type'] ?? '') as String,
          dateTime: (item['dateTime'] ?? '') as String,
          subjectName: (item['subjectName'] ?? '') as String,
          user: (item['user'] ?? '') as String,
          newName: (item['newName'] ?? '') as String,
          newAdditionalInfo:
              (item['newAdditionalInfo'] ?? '') as String,
          action: (item['action'] ?? '') as String,
        ));
      } on Object {
        continue;
      }
    }
    return result;
  }

  List<PortalReprimand> _parseReprimands(List<dynamic> data) {
    final result = <PortalReprimand>[];
    for (final item in data) {
      if (item is! Map<String, dynamic>) continue;
      try {
        result.add(PortalReprimand(
          id: item['id'] as int,
          date: (item['date'] ?? '') as String,
          teacherName: (item['teacherName'] ?? '') as String,
          content: (item['content'] ?? '') as String,
          type: item['type'] as int,
        ));
      } on Object {
        continue;
      }
    }
    return result;
  }

  List<PortalTest> _parseTests(List<dynamic> data) {
    final result = <PortalTest>[];
    for (final item in data) {
      if (item is! Map<String, dynamic>) continue;
      try {
        final dateTime = item['dateTime'] as String?;
        final date = dateTime != null
            ? dateTime.substring(0, 10)
            : (item['date'] ?? '') as String;
        result.add(PortalTest(
          id: item['id'] as int,
          subjectName: (item['subjectName'] ?? '') as String,
          date: date,
          title: item['title'] as String?,
          description: item['description'] as String?,
        ));
      } on Object {
        continue;
      }
    }
    return result;
  }

  List<PortalHomework> _parseHomeworks(List<dynamic> data) {
    final result = <PortalHomework>[];
    for (final item in data) {
      if (item is! Map<String, dynamic>) continue;
      try {
        result.add(PortalHomework(
          id: item['id'] as int,
          subjectName: (item['subjectName'] ?? '') as String,
          date: (item['date'] ?? '') as String,
          dueDate: (item['dueDate'] ?? item['date'] ?? '') as String,
          content: (item['content'] ?? item['description'] ?? '') as String,
        ));
      } on Object {
        continue;
      }
    }
    return result;
  }

  void _applyData(Map<String, dynamic> data) {
    final parser = SyncDataParser();
    final syncData = parser.parse(data);

    if (syncData.students.isNotEmpty) {
      ref.read(studentsProvider.notifier).state = syncData.students;
    }
    if (syncData.teachers.isNotEmpty) {
      ref.read(teachersProvider.notifier).state = syncData.teachers;
    }
    if (syncData.subjects.isNotEmpty) {
      ref.read(subjectsProvider.notifier).state = syncData.subjects;
    }
    if (syncData.terms.isNotEmpty) {
      ref.read(termsProvider.notifier).state = syncData.terms;
    }
    if (syncData.rooms.isNotEmpty) {
      ref.read(roomsProvider.notifier).state = syncData.rooms;
    }
    if (syncData.events.isNotEmpty) {
      ref.read(eventsProvider.notifier).state = syncData.events;
    }
    if (syncData.eventTypes.isNotEmpty) {
      ref.read(eventTypesProvider.notifier).state = syncData.eventTypes;
    }
    if (syncData.eventTypeTeachers.isNotEmpty) {
      ref.read(eventTypeTeachersProvider.notifier).state =
          syncData.eventTypeTeachers;
    }
    if (syncData.eventTypeTerms.isNotEmpty) {
      ref.read(eventTypeTermsProvider.notifier).state =
          syncData.eventTypeTerms;
    }
    if (syncData.eventSubjects.isNotEmpty) {
      ref.read(eventSubjectsProvider.notifier).state = syncData.eventSubjects;
    }
    if (syncData.eventEvents.isNotEmpty) {
      ref.read(eventEventsProvider.notifier).state = syncData.eventEvents;
    }
    if (syncData.marks.isNotEmpty) {
      ref.read(marksProvider.notifier).state = syncData.marks;
    }
    if (syncData.markGroups.isNotEmpty) {
      ref.read(markGroupsProvider.notifier).state = syncData.markGroups;
    }
    if (syncData.markKinds.isNotEmpty) {
      ref.read(markKindsProvider.notifier).state = syncData.markKinds;
    }
    if (syncData.markScales.isNotEmpty) {
      ref.read(markScalesProvider.notifier).state = syncData.markScales;
    }
    if (syncData.markGroupGroups.isNotEmpty) {
      ref.read(markGroupGroupsProvider.notifier).state =
          syncData.markGroupGroups;
    }
    if (syncData.attendances.isNotEmpty) {
      ref.read(attendancesProvider.notifier).state = syncData.attendances;
    }
    if (syncData.attendanceTypes.isNotEmpty) {
      ref.read(attendanceTypesProvider.notifier).state =
          syncData.attendanceTypes;
    }
  }
}

List<PocztaMessage> parsePocztaMessages(List<dynamic> data) {
  final result = <PocztaMessage>[];
  for (final item in data) {
    if (item is! Map<String, dynamic>) continue;
    try {
      final author = item['author'] as Map<String, dynamic>?;
      final senderName = author?['name'] as String? ?? '';

      final dateStr = item['date'] as String?;
      if (dateStr == null) continue;

      result.add(PocztaMessage(
        id: item['id'] as int,
        title: (item['subject'] ?? '') as String,
        senderName: senderName,
        sendTime: DateTime.parse(dateStr),
        preview: item['content'] as String?,
        isRead: item['read_at'] != null,
        isStarred: item['stared'] == true,
        content: item['content'] as String?,
      ));
    } on Object {
      continue;
    }
  }
  return result;
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
