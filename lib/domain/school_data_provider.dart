import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/data/services/notification_service.dart';
import 'package:bsharp/data/services/sync_cache.dart';
import 'package:bsharp/domain/entities/poczta.dart';
import 'package:bsharp/domain/entities/student.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DataProviderCapability {
  grades,
  schedule,
  attendance,
  messages,
  sendMessages,
  homework,
  tests,
  notes,
  bulletins,
  changelog,
  pushNotifications,
}

class ReauthRequiredException implements Exception {
  const ReauthRequiredException();

  @override
  String toString() =>
      'ReauthRequiredException: the saved password is missing or rejected';
}

class PupilNotOnAccountException implements Exception {
  const PupilNotOnAccountException({
    required this.pupilId,
    required this.students,
  });

  final int pupilId;
  final List<Student> students;

  @override
  String toString() =>
      'PupilNotOnAccountException: pupil $pupilId is not on the account';
}

class MessagingException implements Exception {
  const MessagingException(this.failure);

  final AppFailure failure;

  @override
  String toString() =>
      'MessagingException: ${failure.runtimeType} ${failure.message ?? ''}';
}

@immutable
class AccountProbe {
  const AccountProbe({required this.schoolName, required this.students});

  final String? schoolName;
  final List<Student> students;
}

abstract class SchoolDataProvider {
  String get id;
  String get displayName;

  /// The language this backend's free text is written in.
  ///
  /// Teachers write lesson topics, message bodies and notes in this language,
  /// so it is the language to translate *from*. It is not the language of
  /// subject names, attendance types or grade categories: a provider
  /// normalises those to canonical English before they reach core state.
  String get contentLanguage;

  Set<DataProviderCapability> get capabilities;

  bool get requiresCredentials;

  bool supports(DataProviderCapability cap) => capabilities.contains(cap);

  Future<void> authenticate({
    required String school,
    required String login,
    required String password,
  });

  Future<void> loadSchoolData(Ref ref, {required int studentId});

  /// Restores state this provider cached earlier, returning whether anything
  /// was restored. A provider that regenerates its data every load caches
  /// nothing and answers `false`.
  bool hydrateFromCache(Ref ref, SyncCache cache, {required int studentId});

  Future<void> loadMessages(Ref ref);

  Set<DataProviderCapability> staleAreasAfter(Object failure);

  Future<void> refreshMessages(Ref ref);

  Future<Map<String, dynamic>?> readMessage(int messageId);

  Future<List<PocztaReceiver>> searchReceivers(String query);

  Future<void> toggleStar(int messageId);

  Future<void> deleteMessage(int messageId);

  Future<void> restoreMessage(int messageId);

  Future<void> sendMessage({
    required List<String> recipientIds,
    required String title,
    required String content,
    int? previousMessageId,
  });

  Future<List<PocztaMessage>> loadMoreInbox(int skip);

  Future<String?> downloadAttachment(String url, String filename);

  Future<Result<AccountProbe>> probeAccount({
    required String school,
    required String login,
    required String password,
  });

  Future<bool> registerPushToken({
    required String school,
    required String login,
    required String password,
    required String token,
  });

  LocalFcmNotification? parseFcmMessage(RemoteMessage message) => null;
}
