import 'package:freezed_annotation/freezed_annotation.dart';

part 'poczta.freezed.dart';

@freezed
abstract class PocztaMessage with _$PocztaMessage {
  const factory PocztaMessage({
    required int id,
    required String title,
    required String senderName,
    required DateTime sendTime,
    String? preview,
    required bool isRead,
    required bool isStarred,
    String? content,
    List<PocztaAttachment>? files,
  }) = _PocztaMessage;
}

@freezed
abstract class PocztaAttachment with _$PocztaAttachment {
  const factory PocztaAttachment({
    required String name,
    required String url,
  }) = _PocztaAttachment;
}

@freezed
abstract class PocztaReceiver with _$PocztaReceiver {
  const factory PocztaReceiver({
    required String id,
    required String name,
    String? role,
  }) = _PocztaReceiver;

  const PocztaReceiver._();

  String get recipientId => id.startsWith('user_') ? id : 'user_$id';
}
