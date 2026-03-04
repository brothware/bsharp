import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/domain/entities/poczta.dart';
import 'package:bsharp/domain/entities/student.dart';
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
}

abstract class SchoolDataProvider {
  String get id;
  String get displayName;

  Set<DataProviderCapability> get capabilities;

  bool get requiresCredentials;

  bool supports(DataProviderCapability cap) => capabilities.contains(cap);

  Future<void> authenticate({
    required String school,
    required String login,
    required String passwordHash,
  });

  Future<void> loadSchoolData(Ref ref, {required int studentId});

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

  String hashPassword(String password);

  Future<Result<void>> validateCredentials({
    required String school,
    required String login,
    required String passwordHash,
  });

  Future<List<Student>> fetchStudents({
    required String school,
    required String login,
    required String passwordHash,
  });
}
