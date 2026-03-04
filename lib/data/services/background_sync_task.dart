import 'package:bsharp/app/notification_preferences_provider.dart';
import 'package:bsharp/core/network/api_client_factory.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/data/data_sources/remote/auth_service.dart';
import 'package:bsharp/data/data_sources/remote/mobile_sync_data_source.dart';
import 'package:bsharp/data/data_sources/remote/poczta_data_source.dart';
import 'package:bsharp/data/data_sources/remote/portal_data_source.dart';
import 'package:bsharp/data/providers/mobireg_data_provider.dart';
import 'package:bsharp/data/services/notification_service.dart';
import 'package:bsharp/data/services/sync_data_parser.dart';
import 'package:bsharp/data/services/sync_snapshot.dart';
import 'package:bsharp/domain/entities/poczta.dart';
import 'package:bsharp/domain/entities/portal.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackgroundSyncTask {
  Future<bool> execute() async {
    try {
      final storage = CredentialStorage();
      final results = await Future.wait([
        storage.getSchool(),
        storage.getLogin(),
        storage.getPasswordHash(),
        storage.getSelectedStudentId(),
      ]);

      final school = results[0] as String?;
      final login = results[1] as String?;
      final passwordHash = results[2] as String?;
      final studentId = results[3] as int?;

      if (school == null ||
          login == null ||
          passwordHash == null ||
          studentId == null) {
        return false;
      }

      final prefs = await SharedPreferences.getInstance();

      final storedLocale = prefs.getString('locale');
      if (storedLocale != null) {
        await LocaleSettings.setLocaleRaw(storedLocale);
      }

      final notifPrefs = NotificationPreferences.fromSharedPreferences(prefs);
      final previousSnapshot = await SyncSnapshot.load(prefs);

      final factory = ApiClientFactory(
        school: school,
        parentLogin: login,
        parentPassHash: passwordHash,
      );

      final syncData = await _fetchMobileSyncData(factory, studentId);
      if (syncData == null) return false;

      final portalData = await _fetchPortalData(
        factory,
        school,
        login,
        passwordHash,
        studentId,
      );

      final inboxMessages = await _fetchInboxMessages(
        factory,
        school,
        login,
        passwordHash,
      );

      final currentSnapshot = SyncSnapshot.fromSyncData(
        syncData: syncData,
        homeworks: portalData.homeworks,
        tests: portalData.tests,
        reprimands: portalData.reprimands,
        inboxMessages: inboxMessages,
      );

      final changeSet = currentSnapshot.diff(previousSnapshot);
      await currentSnapshot.save(prefs);

      if (changeSet.isNotEmpty) {
        final service = NotificationService();
        await service.initialize();
        await service.requestPermission();
        await service.showChanges(changeSet, notifPrefs);
      }

      return true;
    } on Object {
      return false;
    }
  }

  Future<SyncData?> _fetchMobileSyncData(
    ApiClientFactory factory,
    int studentId,
  ) async {
    final syncDs = MobileSyncDataSource(
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

    final result = await syncDs.fullSync(
      studentId: studentId,
      startDate: startDate,
      endDate: endDate,
    );

    return result.when(
      success: (data) => SyncDataParser().parse(data),
      failure: (_) => null,
    );
  }

  Future<_PortalData> _fetchPortalData(
    ApiClientFactory factory,
    String school,
    String login,
    String passwordHash,
    int pupilId,
  ) async {
    var homeworks = <PortalHomework>[];
    var tests = <PortalTest>[];
    var reprimands = <PortalReprimand>[];

    try {
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

      Future<String?> obtainToken() async {
        final authService = AuthService(
          webLoginClient: ApiClientFactory(
            school: school,
            parentLogin: login,
            parentPassHash: passwordHash,
          ).createWebLoginClient(),
        );
        final result = await authService.obtainPortalToken(
          login: login,
          passwordHash: passwordHash,
        );
        return result.when(success: (t) => t, failure: (_) => null);
      }

      var token = await obtainToken();
      if (token != null) {
        final result = await portalDs.getView(
          school: school,
          token: token,
          view: 'homeworks',
          params: params,
        );
        result.when(
          success: (data) {
            homeworks = _parseHomeworks(data['items'] as List<dynamic>? ?? []);
          },
          failure: (_) {},
        );
      }

      token = await obtainToken();
      if (token != null) {
        final result = await portalDs.getView(
          school: school,
          token: token,
          view: 'tests',
          params: params,
        );
        result.when(
          success: (data) {
            tests = _parseTests(data['items'] as List<dynamic>? ?? []);
          },
          failure: (_) {},
        );
      }

      token = await obtainToken();
      if (token != null) {
        final result = await portalDs.getView(
          school: school,
          token: token,
          view: 'reprimands',
          params: params,
        );
        result.when(
          success: (data) {
            reprimands = _parseReprimands(
              data['items'] as List<dynamic>? ?? [],
            );
          },
          failure: (_) {},
        );
      }
    } on Object {
      // Portal data is best-effort
    }

    return _PortalData(
      homeworks: homeworks,
      tests: tests,
      reprimands: reprimands,
    );
  }

  Future<List<PocztaMessage>> _fetchInboxMessages(
    ApiClientFactory factory,
    String school,
    String login,
    String passwordHash,
  ) async {
    try {
      final authService = AuthService(
        webLoginClient: ApiClientFactory(
          school: school,
          parentLogin: login,
          parentPassHash: passwordHash,
        ).createWebLoginClient(),
      );
      final tokenResult = await authService.obtainPortalToken(
        login: login,
        passwordHash: passwordHash,
      );
      final token = tokenResult.when(
        success: (t) => t,
        failure: (_) => null,
      );
      if (token == null) return [];

      final portalDs = PortalDataSource(client: factory.createPortalClient());
      final userResult = await portalDs.getView(
        school: school,
        token: token,
        view: 'users',
        params: {},
      );
      final messagesToken = userResult.when(
        success: (data) => data['messagesToken'] as String?,
        failure: (_) => null,
      );
      if (messagesToken == null) return [];

      final pocztaDs = PocztaDataSource(client: factory.createPocztaClient());
      final sessionResult = await pocztaDs.establishSession(
        school: school,
        messagesToken: messagesToken,
      );
      final sessionOk = sessionResult.when(
        success: (_) => true,
        failure: (_) => false,
      );
      if (!sessionOk) return [];

      final inboxResult = await pocztaDs.getInbox();
      return inboxResult.when(
        success: (data) {
          final all = parsePocztaMessages(data);
          final today = DateTime.now();
          return all
              .where(
                (m) =>
                    m.sendTime.year == today.year &&
                    m.sendTime.month == today.month &&
                    m.sendTime.day == today.day,
              )
              .toList();
        },
        failure: (_) => [],
      );
    } on Object {
      return [];
    }
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
}

class _PortalData {
  const _PortalData({
    required this.homeworks,
    required this.tests,
    required this.reprimands,
  });

  final List<PortalHomework> homeworks;
  final List<PortalTest> tests;
  final List<PortalReprimand> reprimands;
}
