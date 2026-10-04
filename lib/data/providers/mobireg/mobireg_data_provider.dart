import 'dart:async';

import 'package:bsharp/app/child_provider.dart';
import 'package:bsharp/app/providers/attendance_providers.dart';
import 'package:bsharp/app/providers/grades_providers.dart';
import 'package:bsharp/app/providers/more_providers.dart';
import 'package:bsharp/app/providers/schedule_providers.dart';
import 'package:bsharp/app/reauth_provider.dart';
import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/core/network/api_client_factory.dart';
import 'package:bsharp/data/data_sources/remote/app_api_data_source.dart';
import 'package:bsharp/data/data_sources/remote/app_api_session.dart';
import 'package:bsharp/data/data_sources/remote/app_api_session_registry.dart';
import 'package:bsharp/data/data_sources/remote/poczta_data_source.dart';
import 'package:bsharp/data/providers/mobireg/mobireg_message_handler.dart';
import 'package:bsharp/data/providers/mobireg/mobireg_view_cache.dart';
import 'package:bsharp/data/providers/mobireg/parsers/account_parser.dart';
import 'package:bsharp/data/providers/mobireg/parsers/attendance_parser.dart';
import 'package:bsharp/data/providers/mobireg/parsers/grade_parser.dart';
import 'package:bsharp/data/providers/mobireg/parsers/school_item_parser.dart';
import 'package:bsharp/data/providers/mobireg/parsers/term_parser.dart';
import 'package:bsharp/data/providers/mobireg/parsers/timetable_parser.dart';
import 'package:bsharp/data/services/notification_service.dart';
import 'package:bsharp/data/services/sync_cache.dart';
import 'package:bsharp/domain/change_detection.dart';
import 'package:bsharp/domain/entities/poczta.dart';
import 'package:bsharp/domain/entities/sync_action.dart';
import 'package:bsharp/domain/entities/teacher.dart';
import 'package:bsharp/domain/entities/term.dart';
import 'package:bsharp/domain/school_data_provider.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

const _usersKey = 'users';
const _pupilKey = 'pupil';
const _termsKey = 'terms';
const _subjectsKey = 'subjects';
const _timetableKey = 'timetable';
const _attendanceStatsKey = 'attendance-stats';
const _testsKey = 'tests';
const _reprimandsKey = 'reprimands';
const _announcementsKey = 'announcements';
const _dateLength = 10;
const _attendancesModule = 'attendances';
const _reprimandsModule = 'reprimands';
const _timetableModule = 'timetable';
const _announcementsModule = 'announcements';
const Map<String, DataProviderCapability> _capabilityByModule = {
  _attendancesModule: DataProviderCapability.attendance,
  _reprimandsModule: DataProviderCapability.notes,
  _timetableModule: DataProviderCapability.schedule,
  _announcementsModule: DataProviderCapability.bulletins,
};

bool _isModuleOn(Set<String>? enabledModules, String module) =>
    enabledModules == null || enabledModules.contains(module);

bool _needsTimetable(Set<String>? enabledModules) =>
    _isModuleOn(enabledModules, _timetableModule) ||
    _isModuleOn(enabledModules, _attendancesModule);

class MobiregDataProvider implements SchoolDataProvider {
  MobiregDataProvider({
    ApiClientFactory Function(String school)? clientFactory,
    AppApiSessionRegistry? sessions,
  }) : _clientFactory = clientFactory ?? _productionClientFactory,
       _sessions = sessions ?? AppApiSessionRegistry.shared;

  final ApiClientFactory Function(String school) _clientFactory;
  final AppApiSessionRegistry _sessions;
  String? _school;
  String? _login;
  String _password = '';
  PocztaDataSource? _pocztaDs;
  ({String school, String messagingUrl, String messagesToken})? _mailboxKey;
  Set<String>? _enabledModules;
  var _hasMailbox = true;

  static ApiClientFactory _productionClientFactory(String school) =>
      ApiClientFactory(school: school);

  @override
  String get id => 'mobireg';

  @override
  String get displayName => 'Mobireg';

  @override
  String get contentLanguage => 'pl';

  @override
  Set<DataProviderCapability> get capabilities {
    final capabilities = DataProviderCapability.values.toSet()
      ..remove(DataProviderCapability.homework)
      ..remove(DataProviderCapability.changelog);
    if (!_hasMailbox) {
      capabilities
        ..remove(DataProviderCapability.messages)
        ..remove(DataProviderCapability.sendMessages);
    }
    final enabledModules = _enabledModules;
    if (enabledModules != null) {
      for (final MapEntry(:key, :value) in _capabilityByModule.entries) {
        if (!_isModuleOn(enabledModules, key)) {
          capabilities.remove(value);
        }
      }
    }
    return capabilities;
  }

  @override
  bool get requiresCredentials => true;

  @override
  bool supports(DataProviderCapability cap) => capabilities.contains(cap);

  @override
  Future<Result<AccountProbe>> probeAccount({
    required String school,
    required String login,
    required String password,
  }) async {
    final session = _sessionFor(
      school: school,
      login: login,
      password: password,
    );
    final result = await session.account();
    return switch (result) {
      Failure(:final failure) => Result.failure(failure),
      Success(:final value) => Result.success(_probeOf(parseAccount(value))),
    };
  }

  AccountProbe _probeOf(MobiregAccount account) =>
      AccountProbe(schoolName: account.schoolName, students: account.students);

  @override
  Future<void> authenticate({
    required String school,
    required String login,
    required String password,
  }) async {
    if (school != _school || login != _login) {
      _enabledModules = null;
      _hasMailbox = true;
    }
    _school = school;
    _login = login;
    _password = password;
  }

  AppApiSession _sessionFor({
    required String school,
    required String login,
    required String password,
  }) {
    return _sessions.sessionFor(
      school: school,
      login: login,
      password: password,
      create: () => AppApiSession(
        api: AppApiDataSource(
          client: _clientFactory(school).createAppApiClient(),
        ),
        login: login,
        password: password,
      ),
    );
  }

  AppApiSession? _activeSession(Ref ref) {
    final school = _school;
    final login = _login;
    if (school == null || login == null) {
      return null;
    }
    if (_password.isEmpty) {
      debugPrint('MobiregDataProvider: $school has no password saved');
      ref.read(reauthRequiredProvider.notifier).value = true;
      throw const ReauthRequiredException();
    }
    return _sessionFor(school: school, login: login, password: _password);
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
    );
  }

  @override
  Future<bool> registerPushToken({
    required String school,
    required String login,
    required String password,
    required String token,
  }) async {
    final session = _sessionFor(
      school: school,
      login: login,
      password: password,
    );
    final result = await session.getView(
      'register-fcm',
      params: {'token': token},
    );
    if (result case Failure(:final failure)) {
      debugPrint('MobiregDataProvider: register-fcm failed: $failure');
      return false;
    }
    return true;
  }

  @override
  bool hydrateFromCache(Ref ref, SyncCache cache, {required int studentId}) {
    final views = _MobiregViews.load(MobiregViewCache(cache));
    if (views != null && views.pupilId != studentId) {
      return false;
    }
    if (views != null) {
      _enabledModules = views.enabledModules;
      views.apply(ref);
    }

    for (final folder in _messageFolders) {
      final messages = cache.loadMessages(folder);
      if (messages != null) {
        applyMessages(ref, folder, messages);
      }
    }

    return views != null;
  }

  @override
  Future<void> loadSchoolData(Ref ref, {required int studentId}) async {
    const reprimandLimit = 100;
    final session = _activeSession(ref);
    if (session == null) {
      return;
    }

    final accountData = await _accountListing(
      ref,
      session,
      studentId,
      trustCached: true,
    );
    ref.read(reauthRequiredProvider.notifier).value = false;
    final enabledModules = parseAccount(accountData).enabledModules;
    bool isEnabled(String module) => _isModuleOn(enabledModules, module);

    Future<Object> view(
      String name, [
      Map<String, String> extra = const {},
    ]) async {
      final result = await session.getView(
        name,
        params: {'pupilId': '$studentId', ...extra},
      );
      if (result case Failure(failure: PupilNotOnAccount())) {
        await _accountListing(ref, session, studentId, trustCached: false);
      }
      return _valueOf(ref, name, result).data;
    }

    final terms = await view('terms');
    final subjects = await view('subjects');
    final parsedTerms = parseTerms(terms);
    final marksByTerm = <int, Object>{
      for (final term in parsedTerms.where(_isSemester))
        term.id: await view('marks', {'termId': '${term.id}'}),
    };
    final year =
        parsedTerms.where((term) => term.type == TermType.year).firstOrNull ??
        (throw FormatException(
          'View terms: no school year',
          terms.runtimeType,
        ));
    final timetable = _needsTimetable(enabledModules)
        ? await view('timetable-events', {
            'dateFrom': _day(year.startDate),
            'dateTo': _day(year.endDate),
          })
        : null;
    final attendanceStats = isEnabled(_attendancesModule)
        ? await view('attendance-stats')
        : null;
    final tests = await view('tests');
    final reprimands = isEnabled(_reprimandsModule)
        ? await view('reprimands', {'limit': '$reprimandLimit'})
        : null;
    final announcements = isEnabled(_announcementsModule)
        ? await view('announcements')
        : null;
    _enabledModules = enabledModules;
    _MobiregViews(
        pupilId: studentId,
        account: accountData,
        terms: terms,
        subjects: subjects,
        marksByTerm: marksByTerm,
        timetable: timetable,
        attendanceStats: attendanceStats,
        tests: tests,
        reprimands: reprimands,
        announcements: announcements,
      )
      ..apply(ref)
      ..save(MobiregViewCache(ref.read(syncCacheProvider)));
  }

  Future<Map<String, dynamic>> _accountListing(
    Ref ref,
    AppApiSession session,
    int studentId, {
    required bool trustCached,
  }) async {
    bool lists(Map<String, dynamic> account) =>
        parseAccount(account).students.any((pupil) => pupil.id == studentId);
    if (trustCached) {
      final cached = _valueOf(ref, 'users', await session.account());
      if (lists(cached)) {
        return cached;
      }
    }
    session.forgetAccount();
    final fresh = _valueOf(ref, 'users', await session.account());
    if (lists(fresh)) {
      return fresh;
    }
    throw PupilNotOnAccountException(
      pupilId: studentId,
      students: parseAccount(fresh).students,
    );
  }

  T _valueOf<T>(Ref ref, String view, Result<T> result) {
    if (result case Failure(failure: InvalidCredentials())) {
      debugPrint('MobiregDataProvider: the saved password was rejected');
      ref.read(reauthRequiredProvider.notifier).value = true;
      throw const ReauthRequiredException();
    }
    return switch (result) {
      Success(:final value) => value,
      Failure(:final failure) => throw Exception(
        'Mobireg view $view failed: $failure',
      ),
    };
  }

  @override
  Future<void> loadMessages(Ref ref) async {
    final school = _school;
    final session = _activeSession(ref);
    if (school == null || session == null) {
      return;
    }

    final account = parseAccount(
      _valueOf(ref, 'users', await session.account()),
    );
    final messagingUrl = account.messagingUrl;
    final messagesToken = account.messagesToken;
    if (messagingUrl == null && messagesToken == null) {
      debugPrint('MobiregDataProvider: $school has no mailbox');
      _clearMailbox(ref);
      return;
    }
    if (messagingUrl == null || messagesToken == null) {
      throw const FormatException(
        'View users has only one of messagingUrl and messagesToken',
      );
    }
    _hasMailbox = true;

    final pocztaDs = await _signedInMailbox(
      school: school,
      messagingUrl: messagingUrl,
      messagesToken: messagesToken,
    );
    await _fetchFolders(ref, pocztaDs);
  }

  void _clearMailbox(Ref ref) {
    _hasMailbox = false;
    _pocztaDs = null;
    _mailboxKey = null;
    final cache = ref.read(syncCacheProvider);
    for (final folder in _messageFolders) {
      applyMessages(ref, folder, const []);
      cache.saveMessages(folder, const []);
    }
  }

  Future<PocztaDataSource> _signedInMailbox({
    required String school,
    required String messagingUrl,
    required String messagesToken,
  }) async {
    final key = (
      school: school,
      messagingUrl: messagingUrl,
      messagesToken: messagesToken,
    );
    final current = _pocztaDs;
    if (current != null && current.hasSession && _mailboxKey == key) {
      return current;
    }
    _pocztaDs = null;
    _mailboxKey = null;
    final pocztaDs = PocztaDataSource(
      client: _clientFactory(school).createPocztaClient(messagingUrl),
    );
    _mailValue(
      await pocztaDs.establishSession(
        school: school,
        messagesToken: messagesToken,
      ),
    );
    _pocztaDs = pocztaDs;
    _mailboxKey = key;
    return pocztaDs;
  }

  static const _messageFolders = ['inbox', 'sent', 'trash'];

  Future<void> _fetchFolders(Ref ref, PocztaDataSource pocztaDs) async {
    final results = await Future.wait([
      pocztaDs.getInbox(),
      pocztaDs.getSent(),
      pocztaDs.getTrash(),
    ]);
    final folders = [for (final result in results) _mailValue(result)];
    final cache = ref.read(syncCacheProvider);
    for (final (index, folder) in _messageFolders.indexed) {
      applyMessages(ref, folder, folders[index]);
      cache.saveMessages(folder, folders[index]);
    }
  }

  PocztaDataSource _mailbox() {
    final pocztaDs = _pocztaDs;
    if (pocztaDs == null || !pocztaDs.hasSession) {
      throw const MessagingException(
        SessionExpired(message: 'Poczta has no session'),
      );
    }
    return pocztaDs;
  }

  T _mailValue<T>(Result<T> result) {
    return switch (result) {
      Success(:final value) => value,
      Failure(:final failure) => throw MessagingException(failure),
    };
  }

  @override
  Future<void> refreshMessages(Ref ref) async {
    await _fetchFolders(ref, _mailbox());
  }

  @override
  Future<Map<String, dynamic>?> readMessage(int messageId) async {
    return _mailValue(await _mailbox().readMessage(messageId));
  }

  @override
  Future<List<PocztaReceiver>> searchReceivers(String query) async {
    final data = _mailValue(await _mailbox().searchReceivers(query));
    return [
      for (final item in data)
        if (item is Map<String, dynamic>)
          PocztaReceiver(
            id: (item['id'] ?? '').toString(),
            name: (item['name'] ?? '') as String,
            role: item['role'] as String?,
          )
        else
          throw FormatException(
            'Poczta receivers/search: expected objects',
            item.runtimeType,
          ),
    ];
  }

  @override
  Future<void> toggleStar(int messageId) async {
    _mailValue(await _mailbox().toggleStar(messageId));
  }

  @override
  Future<void> deleteMessage(int messageId) async {
    _mailValue(await _mailbox().deleteMessage(messageId));
  }

  @override
  Future<void> restoreMessage(int messageId) async {
    _mailValue(await _mailbox().restoreMessage(messageId));
  }

  @override
  Future<void> sendMessage({
    required List<String> recipientIds,
    required String title,
    required String content,
    int? previousMessageId,
  }) async {
    _mailValue(
      await _mailbox().sendMessage(
        title: title,
        content: content,
        recipients: recipientIds,
        previousMessageId: previousMessageId,
      ),
    );
  }

  @override
  Future<List<PocztaMessage>> loadMoreInbox(int skip) async {
    final data = _mailValue(await _mailbox().getInbox(skip: skip));
    return parsePocztaMessages(data, 'inbox');
  }

  @override
  Future<String?> downloadAttachment(String url, String filename) async {
    final pocztaDs = _mailbox();
    final dir = await getTemporaryDirectory();
    final savePath = '${dir.path}/$filename';
    _mailValue(await pocztaDs.downloadFile(url, savePath));
    return savePath;
  }
}

bool _isSemester(Term term) => term.type == TermType.semester;

String _day(DateTime date) => date.toIso8601String().substring(0, _dateLength);

@immutable
class _MobiregViews {
  const _MobiregViews({
    required this.pupilId,
    required this.account,
    required this.terms,
    required this.subjects,
    required this.marksByTerm,
    required this.timetable,
    required this.attendanceStats,
    required this.tests,
    required this.reprimands,
    required this.announcements,
  });

  final int pupilId;
  final Map<String, dynamic> account;
  final Object terms;
  final Object subjects;
  final Map<int, Object> marksByTerm;
  final Object? timetable;
  final Object? attendanceStats;
  final Object tests;
  final Object? reprimands;
  final Object? announcements;

  Set<String>? get enabledModules => parseAccount(account).enabledModules;

  static _MobiregViews? load(MobiregViewCache cache) {
    final account = cache.load(_usersKey);
    if (account == null) {
      return null;
    }
    Object stored(String key) =>
        cache.load(key) ??
        (throw FormatException('Cached view $key is missing'));
    final pupilId = stored(_pupilKey);
    if (account is! Map<String, dynamic> || pupilId is! int) {
      throw const FormatException('Cached account is malformed');
    }
    final modules = parseAccount(account).enabledModules;
    Object? storedFor(String module, String key) =>
        _isModuleOn(modules, module) ? stored(key) : null;
    final terms = stored(_termsKey);
    return _MobiregViews(
      pupilId: pupilId,
      account: account,
      terms: terms,
      subjects: stored(_subjectsKey),
      marksByTerm: {
        for (final term in parseTerms(terms).where(_isSemester))
          term.id: stored(_marksKey(term.id)),
      },
      timetable: _needsTimetable(modules) ? stored(_timetableKey) : null,
      attendanceStats: storedFor(_attendancesModule, _attendanceStatsKey),
      tests: stored(_testsKey),
      reprimands: storedFor(_reprimandsModule, _reprimandsKey),
      announcements: storedFor(_announcementsModule, _announcementsKey),
    );
  }

  static String _marksKey(int termId) => 'marks_$termId';

  void save(MobiregViewCache cache) {
    cache
      ..save(_usersKey, account)
      ..save(_pupilKey, pupilId)
      ..save(_termsKey, terms)
      ..save(_subjectsKey, subjects)
      ..save(_testsKey, tests);
    final optionalViews = {
      _timetableKey: timetable,
      _attendanceStatsKey: attendanceStats,
      _reprimandsKey: reprimands,
      _announcementsKey: announcements,
    };
    for (final MapEntry(:key, :value) in optionalViews.entries) {
      if (value != null) {
        cache.save(key, value);
      }
    }
    for (final MapEntry(:key, :value) in marksByTerm.entries) {
      cache.save(_marksKey(key), value);
    }
  }

  void apply(Ref ref) {
    final students = parseAccount(account).students;
    final parsedTerms = parseTerms(terms);
    final parsedSubjects = parseSubjects(subjects);
    final marks = [
      for (final MapEntry(:key, :value) in marksByTerm.entries)
        parseMarks(value, termId: key),
    ];
    final teachers = <int, Teacher>{
      for (final termMarks in marks)
        for (final teacher in termMarks.teachers) teacher.id: teacher,
    };
    final timetableView = timetable;
    final events =
        timetableView != null && _isModuleOn(enabledModules, _timetableModule)
        ? parseTimetableEvents(
            timetableView,
            subjectIdsByName: {
              for (final subject in parsedSubjects) subject.name: subject.id,
            },
          )
        : null;
    final attendanceStatsView = attendanceStats;
    final attendance = timetableView != null && attendanceStatsView != null
        ? parseAttendance(
            timetableEvents: timetableView,
            attendanceStats: attendanceStatsView,
          )
        : null;
    final parsedTests = parseTestItems(tests);
    final reprimandsView = reprimands;
    final parsedReprimands = reprimandsView == null
        ? null
        : parseReprimandItems(reprimandsView);
    final announcementsView = announcements;
    final bulletins = announcementsView == null
        ? null
        : parseAnnouncements(announcementsView);

    ref.read(studentsProvider.notifier).value = students;
    ref.read(termsProvider.notifier).value = parsedTerms;
    ref.read(subjectsProvider.notifier).value = parsedSubjects;
    ref.read(teachersProvider.notifier).value = teachers.values.toList();
    ref.read(resolvedGradesProvider.notifier).value = [
      for (final termMarks in marks) ...termMarks.grades,
    ];
    ref.read(resolvedEventsProvider.notifier).value = events ?? const [];
    ref.read(attendancesProvider.notifier).value =
        attendance?.attendances ?? const [];
    ref.read(attendanceTypesProvider.notifier).value =
        attendance?.types ?? const [];
    ref.read(testsProvider.notifier).value = parsedTests;
    ref.read(reprimandsProvider.notifier).value = parsedReprimands ?? const [];
    ref.read(bulletinsProvider.notifier).value = bulletins ?? const [];
  }
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
  final ChangeCategory? category;

  static _MobiregNotificationKind forKey(String key) {
    final known = values.where((kind) => kind.key == key).firstOrNull;
    if (known != null) {
      return known;
    }
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
    exams || announcements || other => t.notification.generalDescription,
  };
}
