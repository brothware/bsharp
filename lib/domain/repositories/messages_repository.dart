import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/domain/entities/poczta.dart';

abstract interface class MessagesRepository {
  Future<Result<List<PocztaMessage>>> getInbox({int? page, int? limit});

  Future<Result<List<PocztaMessage>>> getSent({int? page, int? limit});

  Future<Result<List<PocztaMessage>>> getTrash();

  Future<Result<PocztaMessage>> readMessage(int messageId);

  Future<Result<void>> sendMessage({
    required String title,
    required String content,
    required List<int> recipientIds,
    List<int>? copyToIds,
    int? previousMessageId,
  });

  Future<Result<void>> deleteMessage(int messageId);

  Future<Result<void>> toggleStar(int messageId);

  Future<Result<void>> restoreMessage(int messageId);

  Future<Result<List<PocztaReceiver>>> getReceivers();

  Future<Result<List<PocztaReceiver>>> searchReceivers(String query);
}
