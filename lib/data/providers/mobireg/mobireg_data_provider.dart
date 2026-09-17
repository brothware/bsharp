import 'dart:async';

import 'package:bsharp/app/providers/messages_providers.dart';
import 'package:bsharp/app/reauth_provider.dart';
import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/core/network/api_client_factory.dart';
import 'package:bsharp/data/data_sources/remote/auth_service.dart';
import 'package:bsharp/data/data_sources/remote/mobile_sync_data_source.dart';
import 'package:bsharp/data/data_sources/remote/poczta_data_source.dart';
import 'package:bsharp/data/data_sources/remote/portal_data_source.dart';
import 'package:bsharp/data/data_sources/remote/portal_session.dart';
import 'package:bsharp/data/providers/mobireg/mobireg_message_handler.dart';
import 'package:bsharp/data/providers/mobireg/mobireg_sync_applier.dart';
import 'package:bsharp/data/services/notification_service.dart';
import 'package:bsharp/data/services/sync_cache.dart';
import 'package:bsharp/domain/change_detection.dart';
import 'package:bsharp/domain/entities/poczta.dart';
import 'package:bsharp/domain/entities/student.dart';
import 'package:bsharp/domain/entities/sync_action.dart';
import 'package:bsharp/domain/school_data_provider.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

class SendMessageException implements Exception {
  SendMessageException(this.failure);

  final AppFailure failure;
}

class MobiregDataProvider implements SchoolDataProvider {
  ApiClientFactory? _factory;
  String? _school;
  String? _login;
  String _password = '';
  String? _legacyPasswordHash;
  PocztaDataSource? _pocztaDs;
  PortalSessionManager? _portalSessions;

  String? get _njsonPassHash =>
      _password.isNotEmpty ? hashPassword(_password) : _legacyPasswordHash;

  bool get _needsReauth => _password.isEmpty && _legacyPasswordHash != null;

  @override
  String get id => 'mobireg';

  @override
  String get displayName => 'Mobireg';

  @override
  String get contentLanguage => 'pl';

  @override
  Set<DataProviderCapability> get capabilities =>
      DataProviderCapability.values.toSet();

  @override
  bool get requiresCredentials => true;

  @override
  bool supports(DataProviderCapability cap) => capabilities.contains(cap);

  @override
  String hashPassword(String password) => AuthService.hashPassword(password);

  @override
  Future<Result<String?>> validateCredentials({
    required String school,
    required String login,
    required String passwordHash,
  }) async {
    final factory = ApiClientFactory(
      school: school,
      parentLogin: login,
      parentPassHash: passwordHash,
    );
    final syncDs = MobileSyncDataSource(
      client: factory.createMobileSyncClient(),
    );
    final result = await syncDs.getSettings();
    return result.when(
      success: (data) {
        final settingsRaw = data['Settings'];
        String? schoolName;
        if (settingsRaw is List && settingsRaw.isNotEmpty) {
          final first = settingsRaw.first;
          if (first is Map<String, dynamic>) {
            schoolName = first['schoolName'] as String?;
          }
        } else if (settingsRaw is Map<String, dynamic>) {
          schoolName = settingsRaw['schoolName'] as String?;
        }
        return Result.success(schoolName);
      },
      failure: Result.failure,
    );
  }

  @override
  Future<Result<List<Student>>> fetchStudents({
    required String school,
    required String login,
    required String passwordHash,
  }) async {
    final factory = ApiClientFactory(
      school: school,
      parentLogin: login,
      parentPassHash: passwordHash,
    );
    final syncDs = MobileSyncDataSource(
      client: factory.createMobileSyncClient(),
    );
    final result = await syncDs.getStudents();
    return result.when(
      success: (data) {
        final studentsJson = data['ParentStudents'] as List<dynamic>? ?? [];
        return Result.success(
          studentsJson
              .whereType<Map<String, dynamic>>()
              .map(
                (json) => Student(
                  id: json['id'] as int,
                  usersEduId: json['users_edu_id'] as int,
                  name: json['name'] as String,
                  surname: json['surname'] as String,
                  sex: Sex.fromString(json['sex'] as String),
                ),
              )
              .toList(),
        );
      },
      failure: Result.failure,
    );
  }

  @override
  Future<void> authenticate({
    required String school,
    required String login,
    required String password,
    String? legacyPasswordHash,
  }) async {
    final sameAccount =
        _factory != null &&
        _school == school &&
        _login == login &&
        _password == password &&
        _legacyPasswordHash == legacyPasswordHash;
    // Every sync re-authenticates, and so does a pull to refresh. Throwing the
    // portal session away here would mean a fresh login each time, which is
    // the burst the server asked us to stop making. The session outlives a
    // sync; only a different account has to start a new one.
    if (sameAccount) return;

    _school = school;
    _login = login;
    _password = password;
    _legacyPasswordHash = legacyPasswordHash;
    _factory = ApiClientFactory(
      school: school,
      parentLogin: login,
      parentPassHash: _njsonPassHash ?? '',
    );
    _portalSessions = null;
  }

  PortalSessionManager _portalSessionManager(ApiClientFactory factory) {
    return _portalSessions ??= PortalSessionManager(
      auth: AuthService(webLoginClient: factory.createWebLoginClient()),
      portal: PortalDataSource(client: factory.createPortalClient()),
      school: _school!,
      login: _login!,
      password: _password,
    );
  }

  Future<PortalSession?> _openPortalSession(
    Ref ref,
    PortalSessionManager sessions,
  ) async {
    final result = await sessions.ensureSession();
    return result.when(
      success: (session) {
        ref.read(portalReauthRequiredProvider.notifier).value = false;
        return session;
      },
      failure: (failure) {
        debugPrint('MobiregDataProvider: portal login failed: $failure');
        return null;
      },
    );
  }

  @override
  LocalFcmNotification? parseFcmMessage(RemoteMessage message) {
    final data = message.data;
    final title = data['title'] as String? ?? '';
    if (title.isEmpty) return null;

    final kind = _MobiregNotificationKind.forKey(data['kind'] as String? ?? '');

    return LocalFcmNotification(
      title: title,
      body: data['body'] as String? ?? '',
      channelId: kind.channelId,
      channelName: kind.channelName,
      channelDescription: kind.channelDescription,
      category: kind.category,
      itemId: int.tryParse(data['id'] as String? ?? ''),
      triggersSync: data['noSync'] != 'true',
    );
  }

  @override
  Future<bool> registerPushToken({
    required String school,
    required String login,
    required String passwordHash,
    required String token,
  }) async {
    final factory = ApiClientFactory(
      school: school,
      parentLogin: login,
      parentPassHash: passwordHash,
    );
    final syncDs = MobileSyncDataSource(
      client: factory.createTokenUploadClient(),
    );
    final result = await syncDs.registerFcmToken(token: token);
    return result.when(success: (_) => true, failure: (_) => false);
  }

  @override
  bool hydrateFromCache(Ref ref, SyncCache cache) {
    final syncData = cache.loadSyncData();
    if (syncData != null) {
      applySyncData(ref, syncData);
    }

    const portalViews = {
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

    for (final kind in ['mark', 'attendance']) {
      final changelog = cache.loadPortalView('changelog_$kind');
      if (changelog != null) {
        applyPortalChangelog(ref, kind, changelog);
      }
    }

    for (final folder in ['inbox', 'sent', 'trash']) {
      final messages = cache.loadMessages(folder);
      if (messages != null) {
        applyMessages(ref, folder, messages);
      }
    }

    return syncData != null;
  }

  @override
  Future<void> loadSchoolData(Ref ref, {required int studentId}) async {
    final factory = _factory;
    if (factory == null) return;

    final syncDataSource = MobileSyncDataSource(
      client: factory.createMobileSyncClient(),
    );

    final now = DateTime.now();
    final startDate = now
        .subtract(const Duration(days: 100))
        .toIso8601String()
        .substring(0, 10);
    final endDate = now
        .add(const Duration(days: 100))
        .toIso8601String()
        .substring(0, 10);

    final result = await syncDataSource.fullSync(
      studentId: studentId,
      startDate: startDate,
      endDate: endDate,
    );

    final cache = ref.read(syncCacheProvider);

    final syncOk = result.when(
      success: (data) {
        applySyncData(ref, data);
        cache.saveSyncData(data);
        return true;
      },
      failure: (_) => false,
    );

    if (!syncOk) throw Exception('Sync failed');

    await _syncPortalData(ref, factory, studentId, cache);
  }

  @override
  Future<void> loadMessages(Ref ref) async {
    final factory = _factory;
    if (factory == null || _login == null || _school == null) {
      return;
    }

    if (_needsReauth) {
      debugPrint('MobiregDataProvider: portal reauth required, skip messages');
      ref.read(portalReauthRequiredProvider.notifier).value = true;
      return;
    }

    final session = await _openPortalSession(
      ref,
      _portalSessionManager(factory),
    );
    if (session == null) return;

    final messagesToken = session.messagesToken;
    if (messagesToken == null) {
      debugPrint('MobiregDataProvider: no messagesToken in users view');
      return;
    }

    final pocztaDs = PocztaDataSource(client: factory.createPocztaClient());
    final sessionResult = await pocztaDs.establishSession(
      school: _school!,
      messagesToken: messagesToken,
    );

    final sessionOk = sessionResult.when(
      success: (_) => true,
      failure: (failure) {
        debugPrint('MobiregDataProvider: poczta session failed: $failure');
        return false;
      },
    );
    if (!sessionOk) return;

    _pocztaDs = pocztaDs;

    final cache = ref.read(syncCacheProvider);

    final results = await Future.wait([
      pocztaDs.getInbox(),
      pocztaDs.getSent(),
      pocztaDs.getTrash(),
    ]);

    results[0].when(
      success: (data) {
        ref.read(inboxProvider.notifier).value = parsePocztaMessages(data);
        cache.saveMessages('inbox', data);
      },
      failure: (failure) =>
          debugPrint('MobiregDataProvider: message fetch failed: $failure'),
    );
    results[1].when(
      success: (data) {
        ref.read(sentProvider.notifier).value = parsePocztaMessages(data);
        cache.saveMessages('sent', data);
      },
      failure: (failure) =>
          debugPrint('MobiregDataProvider: message fetch failed: $failure'),
    );
    results[2].when(
      success: (data) {
        ref.read(trashProvider.notifier).value = parsePocztaMessages(data);
        cache.saveMessages('trash', data);
      },
      failure: (failure) =>
          debugPrint('MobiregDataProvider: message fetch failed: $failure'),
    );
  }

  @override
  Future<void> refreshMessages(Ref ref) async {
    final pocztaDs = _pocztaDs;
    if (pocztaDs == null || !pocztaDs.hasSession) return;

    final results = await Future.wait([
      pocztaDs.getInbox(),
      pocztaDs.getSent(),
      pocztaDs.getTrash(),
    ]);

    final cache = ref.read(syncCacheProvider);

    results[0].when(
      success: (data) {
        ref.read(inboxProvider.notifier).value = parsePocztaMessages(data);
        cache.saveMessages('inbox', data);
      },
      failure: (failure) =>
          debugPrint('MobiregDataProvider: message fetch failed: $failure'),
    );
    results[1].when(
      success: (data) {
        ref.read(sentProvider.notifier).value = parsePocztaMessages(data);
        cache.saveMessages('sent', data);
      },
      failure: (failure) =>
          debugPrint('MobiregDataProvider: message fetch failed: $failure'),
    );
    results[2].when(
      success: (data) {
        ref.read(trashProvider.notifier).value = parsePocztaMessages(data);
        cache.saveMessages('trash', data);
      },
      failure: (failure) =>
          debugPrint('MobiregDataProvider: message fetch failed: $failure'),
    );
  }

  @override
  Future<Map<String, dynamic>?> readMessage(int messageId) async {
    final pocztaDs = _pocztaDs;
    if (pocztaDs == null || !pocztaDs.hasSession) return null;

    final result = await pocztaDs.readMessage(messageId);
    return result.when(success: (data) => data, failure: (_) => null);
  }

  @override
  Future<List<PocztaReceiver>> searchReceivers(String query) async {
    final pocztaDs = _pocztaDs;
    if (pocztaDs == null || !pocztaDs.hasSession) return [];

    final result = await pocztaDs.searchReceivers(query);
    return result.when(
      success: (data) {
        final receivers = <PocztaReceiver>[];
        for (final item in data) {
          if (item is! Map<String, dynamic>) continue;
          receivers.add(
            PocztaReceiver(
              id: (item['id'] ?? '').toString(),
              name: (item['name'] ?? '') as String,
              role: item['role'] as String?,
            ),
          );
        }
        return receivers;
      },
      failure: (_) => [],
    );
  }

  @override
  Future<void> toggleStar(int messageId) async {
    await _pocztaDs?.toggleStar(messageId);
  }

  @override
  Future<void> deleteMessage(int messageId) async {
    await _pocztaDs?.deleteMessage(messageId);
  }

  @override
  Future<void> restoreMessage(int messageId) async {
    await _pocztaDs?.restoreMessage(messageId);
  }

  @override
  Future<void> sendMessage({
    required List<String> recipientIds,
    required String title,
    required String content,
    int? previousMessageId,
  }) async {
    final result = await _pocztaDs?.sendMessage(
      title: title,
      content: content,
      recipients: recipientIds,
      previousMessageId: previousMessageId,
    );
    if (result case Failure(:final failure)) {
      throw SendMessageException(failure);
    }
  }

  @override
  Future<List<PocztaMessage>> loadMoreInbox(int skip) async {
    final pocztaDs = _pocztaDs;
    if (pocztaDs == null || !pocztaDs.hasSession) return [];

    final result = await pocztaDs.getInbox(skip: skip);
    return result.when(success: parsePocztaMessages, failure: (_) => []);
  }

  @override
  Future<String?> downloadAttachment(String url, String filename) async {
    final pocztaDs = _pocztaDs;
    if (pocztaDs == null || !pocztaDs.hasSession) return null;

    final dir = await getTemporaryDirectory();
    final savePath = '${dir.path}/$filename';
    final result = await pocztaDs.downloadFile(url, savePath);
    return result.when(success: (_) => savePath, failure: (_) => null);
  }

  Future<void> _syncPortalData(
    Ref ref,
    ApiClientFactory factory,
    int pupilId,
    SyncCache cache,
  ) async {
    if (_needsReauth) {
      debugPrint('MobiregDataProvider: portal reauth required, skip portal');
      ref.read(portalReauthRequiredProvider.notifier).value = true;
      return;
    }
    final sessions = _portalSessionManager(factory);
    if (await _openPortalSession(ref, sessions) == null) return;

    final now = DateTime.now();
    final schoolYearStart = now.month >= 9
        ? DateTime(now.year, 9)
        : DateTime(now.year - 1, 9);
    final schoolYearEnd = DateTime(schoolYearStart.year + 1, 8, 31);
    final dateFrom = schoolYearStart.toIso8601String().substring(0, 10);
    final dateTo = schoolYearEnd.toIso8601String().substring(0, 10);
    final pupilIdStr = pupilId.toString();

    final params = {
      'pupilId': pupilIdStr,
      'dateFrom': dateFrom,
      'dateTo': dateTo,
    };

    final changelogParams = {...params, 'limit': '100', 'offset': '0'};

    final views = <_PortalViewRequest>[
      _PortalViewRequest(
        view: 'bulletins',
        params: params,
        apply: (items) => applyPortalBulletins(ref, items),
      ),
      _PortalViewRequest(
        view: 'changelog',
        params: {...changelogParams, 'type': 'mark'},
        apply: (items) => applyPortalChangelog(ref, 'mark', items),
        cacheKey: 'changelog_mark',
      ),
      _PortalViewRequest(
        view: 'changelog',
        params: {...changelogParams, 'type': 'attendance'},
        apply: (items) => applyPortalChangelog(ref, 'attendance', items),
        cacheKey: 'changelog_attendance',
      ),
      _PortalViewRequest(
        view: 'reprimands',
        params: params,
        apply: (items) => applyPortalReprimands(ref, items),
      ),
      _PortalViewRequest(
        view: 'tests',
        params: params,
        apply: (items) => applyPortalTests(ref, items),
      ),
      _PortalViewRequest(
        view: 'homeworks',
        params: params,
        apply: (items) => applyPortalHomeworks(ref, items),
      ),
    ];

    for (final request in views) {
      final result = await sessions.getView(
        view: request.view,
        params: request.params,
      );
      result.when(
        success: (data) {
          final items = data['items'] as List<dynamic>? ?? [];
          request.apply(items);
          cache.savePortalView(request.cacheKey ?? request.view, items);
        },
        failure: (failure) => debugPrint(
          'MobiregDataProvider: portal view ${request.view} failed: $failure',
        ),
      );
    }
  }
}

class _PortalViewRequest {
  const _PortalViewRequest({
    required this.view,
    required this.params,
    required this.apply,
    this.cacheKey,
  });

  final String view;
  final Map<String, String> params;
  final void Function(List<dynamic> items) apply;
  final String? cacheKey;
}

enum _MobiregNotificationKind {
  messages('messages', 'messages', ChangeCategory.messages),
  marks('marks', 'grades', ChangeCategory.grades),
  absences('absences', 'attendance', ChangeCategory.attendance),
  reprimands('reprimands', 'notes', ChangeCategory.notes),
  timetables('timetables', 'schedule', ChangeCategory.schedule),
  substitutions('substitutions', 'schedule', ChangeCategory.schedule),
  cancellations('cancellations', 'schedule', ChangeCategory.schedule),
  planChanges('planChanges', 'schedule', ChangeCategory.schedule),
  exams('exams', 'tests', ChangeCategory.tests),
  announcements('announcements', 'bulletins', ChangeCategory.bulletins),
  other('other', 'general', null);

  const _MobiregNotificationKind(this.key, this.channelId, this.category);

  final String key;
  final String channelId;

  /// Null for [other]: the server named something this app cannot place.
  final ChangeCategory? category;

  static _MobiregNotificationKind forKey(String key) {
    final known = values.where((kind) => kind.key == key).firstOrNull;
    if (known != null) return known;
    // The server has renamed a kind, or added one. Say so: swallowing it
    // silently is how every push ends up on the dashboard.
    debugPrint('MobiregDataProvider: unknown notification kind "$key"');
    return other;
  }

  String get channelName => switch (this) {
    messages => t.notification.messagesName,
    marks => t.notification.gradesName,
    absences => t.notification.attendanceName,
    reprimands => t.notification.notesName,
    timetables ||
    substitutions ||
    cancellations ||
    planChanges => t.notification.scheduleName,
    exams => t.tests.title,
    announcements => t.bulletins.title,
    other => t.notification.generalName,
  };

  String get channelDescription => switch (this) {
    messages => t.notification.messagesDescription,
    marks => t.notification.gradesDescription,
    absences => t.notification.attendanceDescription,
    reprimands => t.notification.notesDescription,
    timetables ||
    substitutions ||
    cancellations ||
    planChanges => t.notification.scheduleDescription,
    // These two have no description of their own translated yet.
    exams || announcements => t.notification.generalDescription,
    other => t.notification.generalDescription,
  };
}
