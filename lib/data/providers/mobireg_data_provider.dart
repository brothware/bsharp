import 'package:bsharp/app/child_provider.dart';
import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/core/network/api_client_factory.dart';
import 'package:bsharp/data/data_sources/remote/auth_service.dart';
import 'package:bsharp/data/data_sources/remote/mobile_sync_data_source.dart';
import 'package:bsharp/data/data_sources/remote/poczta_data_source.dart';
import 'package:bsharp/data/data_sources/remote/portal_data_source.dart';
import 'package:bsharp/data/services/sync_data_parser.dart';
import 'package:bsharp/domain/entities/poczta.dart';
import 'package:bsharp/domain/entities/portal.dart';
import 'package:bsharp/domain/entities/student.dart';
import 'package:bsharp/domain/entities/sync_action.dart';
import 'package:bsharp/domain/school_data_provider.dart';
import 'package:bsharp/presentation/attendance/providers/attendance_providers.dart';
import 'package:bsharp/presentation/grades/providers/grades_providers.dart';
import 'package:bsharp/presentation/messages/providers/messages_providers.dart';
import 'package:bsharp/presentation/more/providers/more_providers.dart';
import 'package:bsharp/presentation/schedule/providers/schedule_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

class MobiregDataProvider implements SchoolDataProvider {
  ApiClientFactory? _factory;
  String? _school;
  String? _login;
  String? _passwordHash;
  PocztaDataSource? _pocztaDs;

  @override
  String get id => 'mobireg';

  @override
  String get displayName => 'Mobireg';

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
  Future<Result<void>> validateCredentials({
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
      success: (_) => const Result.success(null),
      failure: Result.failure,
    );
  }

  @override
  Future<List<Student>> fetchStudents({
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
        return studentsJson
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
            .toList();
      },
      failure: (_) => throw Exception('Failed to fetch students'),
    );
  }

  @override
  Future<void> authenticate({
    required String school,
    required String login,
    required String passwordHash,
  }) async {
    _school = school;
    _login = login;
    _passwordHash = passwordHash;
    _factory = ApiClientFactory(
      school: school,
      parentLogin: login,
      parentPassHash: passwordHash,
    );
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

    final syncOk = result.when(
      success: (data) {
        _applyData(ref, data);
        return true;
      },
      failure: (_) => false,
    );

    if (!syncOk) throw Exception('Sync failed');

    await _syncPortalData(ref, factory, studentId);
  }

  @override
  Future<void> loadMessages(Ref ref) async {
    final factory = _factory;
    if (factory == null ||
        _login == null ||
        _passwordHash == null ||
        _school == null) {
      return;
    }

    final authService = AuthService(
      webLoginClient: factory.createWebLoginClient(),
    );
    final tokenResult = await authService.obtainPortalToken(
      login: _login!,
      passwordHash: _passwordHash!,
    );

    final token = tokenResult.when(success: (t) => t, failure: (_) => null);
    if (token == null) return;

    final portalDs = PortalDataSource(client: factory.createPortalClient());
    final userResult = await portalDs.getView(
      school: _school!,
      token: token,
      view: 'users',
      params: {},
    );

    final messagesToken = userResult.when(
      success: (data) => data['messagesToken'] as String?,
      failure: (_) => null,
    );

    if (messagesToken == null) return;

    final pocztaDs = PocztaDataSource(client: factory.createPocztaClient());
    final sessionResult = await pocztaDs.establishSession(
      school: _school!,
      messagesToken: messagesToken,
    );

    final sessionOk = sessionResult.when(
      success: (_) => true,
      failure: (_) => false,
    );
    if (!sessionOk) return;

    _pocztaDs = pocztaDs;

    final inboxResult = await pocztaDs.getInbox();
    inboxResult.when(
      success: (data) {
        ref.read(inboxProvider.notifier).value = parsePocztaMessages(data);
      },
      failure: (_) {},
    );

    final sentResult = await pocztaDs.getSent();
    sentResult.when(
      success: (data) {
        ref.read(sentProvider.notifier).value = parsePocztaMessages(data);
      },
      failure: (_) {},
    );

    final trashResult = await pocztaDs.getTrash();
    trashResult.when(
      success: (data) {
        ref.read(trashProvider.notifier).value = parsePocztaMessages(data);
      },
      failure: (_) {},
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

    results[0].when(
      success: (data) {
        ref.read(inboxProvider.notifier).value = parsePocztaMessages(data);
      },
      failure: (_) {},
    );
    results[1].when(
      success: (data) {
        ref.read(sentProvider.notifier).value = parsePocztaMessages(data);
      },
      failure: (_) {},
    );
    results[2].when(
      success: (data) {
        ref.read(trashProvider.notifier).value = parsePocztaMessages(data);
      },
      failure: (_) {},
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
    await _pocztaDs?.sendMessage(
      title: title,
      content: content,
      recipients: recipientIds,
      previousMessageId: previousMessageId,
    );
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

  void _applyData(Ref ref, Map<String, dynamic> data) {
    final parser = SyncDataParser();
    final syncData = parser.parse(data);

    if (syncData.students.isNotEmpty) {
      ref.read(studentsProvider.notifier).value = syncData.students;
    }
    if (syncData.teachers.isNotEmpty) {
      ref.read(teachersProvider.notifier).value = syncData.teachers;
    }
    if (syncData.subjects.isNotEmpty) {
      ref.read(subjectsProvider.notifier).value = syncData.subjects;
    }
    if (syncData.terms.isNotEmpty) {
      ref.read(termsProvider.notifier).value = syncData.terms;
    }
    if (syncData.rooms.isNotEmpty) {
      ref.read(roomsProvider.notifier).value = syncData.rooms;
    }
    if (syncData.events.isNotEmpty) {
      ref.read(eventsProvider.notifier).value = syncData.events;
    }
    if (syncData.eventTypes.isNotEmpty) {
      ref.read(eventTypesProvider.notifier).value = syncData.eventTypes;
    }
    if (syncData.eventTypeTeachers.isNotEmpty) {
      ref.read(eventTypeTeachersProvider.notifier).value =
          syncData.eventTypeTeachers;
    }
    if (syncData.eventTypeTerms.isNotEmpty) {
      ref.read(eventTypeTermsProvider.notifier).value = syncData.eventTypeTerms;
    }
    if (syncData.eventSubjects.isNotEmpty) {
      ref.read(eventSubjectsProvider.notifier).value = syncData.eventSubjects;
    }
    if (syncData.eventEvents.isNotEmpty) {
      ref.read(eventEventsProvider.notifier).value = syncData.eventEvents;
    }
    if (syncData.marks.isNotEmpty) {
      ref.read(marksProvider.notifier).value = syncData.marks;
    }
    if (syncData.markGroups.isNotEmpty) {
      ref.read(markGroupsProvider.notifier).value = syncData.markGroups;
    }
    if (syncData.markKinds.isNotEmpty) {
      ref.read(markKindsProvider.notifier).value = syncData.markKinds;
    }
    if (syncData.markScales.isNotEmpty) {
      ref.read(markScalesProvider.notifier).value = syncData.markScales;
    }
    if (syncData.markGroupGroups.isNotEmpty) {
      ref.read(markGroupGroupsProvider.notifier).value =
          syncData.markGroupGroups;
    }
    if (syncData.attendances.isNotEmpty) {
      ref.read(attendancesProvider.notifier).value = syncData.attendances;
    }
    if (syncData.attendanceTypes.isNotEmpty) {
      ref.read(attendanceTypesProvider.notifier).value =
          syncData.attendanceTypes;
    }
  }

  Future<void> _syncPortalData(
    Ref ref,
    ApiClientFactory factory,
    int pupilId,
  ) async {
    final authService = AuthService(
      webLoginClient: factory.createWebLoginClient(),
    );
    final tokenResult = await authService.obtainPortalToken(
      login: _login!,
      passwordHash: _passwordHash!,
    );
    final token = tokenResult.when(success: (t) => t, failure: (_) => null);
    if (token == null) return;

    final portalDs = PortalDataSource(client: factory.createPortalClient());
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

    await _fetchPortalView(
      ref,
      portalDs,
      token,
      'bulletins',
      params,
      (items) =>
          ref.read(bulletinsProvider.notifier).value = _parseBulletins(items),
    );

    final changelogParams = {...params, 'limit': '100', 'offset': '0'};

    Future<String?> refreshToken() async {
      final result = await AuthService(
        webLoginClient: ApiClientFactory(
          school: _school!,
          parentLogin: _login!,
          parentPassHash: _passwordHash!,
        ).createWebLoginClient(),
      ).obtainPortalToken(login: _login!, passwordHash: _passwordHash!);
      return result.when(success: (t) => t, failure: (_) => null);
    }

    await _fetchPortalView(
      ref,
      portalDs,
      await refreshToken(),
      'changelog',
      {...changelogParams, 'type': 'mark'},
      (items) => ref.read(gradeChangelogProvider.notifier).value =
          _parseChangelog(items),
    );

    await _fetchPortalView(
      ref,
      portalDs,
      await refreshToken(),
      'changelog',
      {...changelogParams, 'type': 'attendance'},
      (items) => ref.read(attendanceChangelogProvider.notifier).value =
          _parseChangelog(items),
    );

    await _fetchPortalView(
      ref,
      portalDs,
      await refreshToken(),
      'reprimands',
      params,
      (items) =>
          ref.read(reprimandsProvider.notifier).value = _parseReprimands(items),
    );

    await _fetchPortalView(
      ref,
      portalDs,
      await refreshToken(),
      'tests',
      params,
      (items) => ref.read(testsProvider.notifier).value = _parseTests(items),
    );

    await _fetchPortalView(
      ref,
      portalDs,
      await refreshToken(),
      'homeworks',
      params,
      (items) =>
          ref.read(homeworksProvider.notifier).value = _parseHomeworks(items),
    );
  }

  Future<void> _fetchPortalView(
    Ref ref,
    PortalDataSource portalDs,
    String? token,
    String view,
    Map<String, String> params,
    void Function(List<dynamic> items) onSuccess,
  ) async {
    if (token == null) return;

    final result = await portalDs.getView(
      school: _school!,
      token: token,
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

  List<PortalBulletin> _parseBulletins(List<dynamic> data) {
    final result = <PortalBulletin>[];
    for (final item in data) {
      if (item is! Map<String, dynamic>) continue;
      try {
        result.add(
          PortalBulletin(
            id: item['id'] as int,
            title: (item['title'] ?? '') as String,
            content: '',
            date: (item['dateTime'] ?? '') as String,
            author: (item['author'] ?? '') as String,
            isRead: item['read'] != null,
          ),
        );
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
        result.add(
          PortalChangelog(
            type: (item['type'] ?? '') as String,
            dateTime: (item['dateTime'] ?? '') as String,
            subjectName: (item['subjectName'] ?? '') as String,
            user: (item['user'] ?? '') as String,
            newName: (item['newName'] ?? '') as String,
            newAdditionalInfo: (item['newAdditionalInfo'] ?? '') as String,
            action: (item['action'] ?? '') as String,
          ),
        );
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
        result.add(
          PortalReprimand(
            id: item['id'] as int,
            date: (item['date'] ?? '') as String,
            teacherName: (item['teacherName'] ?? '') as String,
            content: (item['content'] ?? '') as String,
            type: item['type'] as int,
          ),
        );
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
        result.add(
          PortalTest(
            id: item['id'] as int,
            subjectName: (item['subjectName'] ?? '') as String,
            date: date,
            title: item['title'] as String?,
            description: item['description'] as String?,
          ),
        );
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
        result.add(
          PortalHomework(
            id: item['id'] as int,
            subjectName: (item['subjectName'] ?? '') as String,
            date: (item['date'] ?? '') as String,
            dueDate: (item['dueDate'] ?? item['date'] ?? '') as String,
            content: (item['content'] ?? item['description'] ?? '') as String,
          ),
        );
      } on Object {
        continue;
      }
    }
    return result;
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

      result.add(
        PocztaMessage(
          id: item['id'] as int,
          title: (item['subject'] ?? '') as String,
          senderName: senderName,
          sendTime: DateTime.parse(dateStr),
          preview: item['content'] as String?,
          isRead: item['read_at'] != null,
          isStarred: item['stared'] == true,
          content: item['content'] as String?,
        ),
      );
    } on Object {
      continue;
    }
  }
  return result;
}
