import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/data/services/notification_service.dart';
import 'package:bsharp/data/services/sync_cache.dart';
import 'package:bsharp/domain/entities/poczta.dart';
import 'package:bsharp/domain/entities/student.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
    String? legacyPasswordHash,
  });

  Future<void> loadSchoolData(Ref ref, {required int studentId});

  /// Restores state this provider cached earlier, returning whether anything
  /// was restored. A provider that regenerates its data every load caches
  /// nothing and answers `false`.
  bool hydrateFromCache(Ref ref, SyncCache cache);

  Future<void> loadMessages(Ref ref);

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

  String hashPassword(String password);

  Future<Result<String?>> validateCredentials({
    required String school,
    required String login,
    required String passwordHash,
  });

  Future<Result<List<Student>>> fetchStudents({
    required String school,
    required String login,
    required String passwordHash,
  });

  Future<bool> registerPushToken({
    required String school,
    required String login,
    required String passwordHash,
    required String token,
  });

  LocalFcmNotification? parseFcmMessage(RemoteMessage message) => null;
}
