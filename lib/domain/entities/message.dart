import 'package:freezed_annotation/freezed_annotation.dart';

part 'message.freezed.dart';

@freezed
abstract class Message with _$Message {
  const factory Message({
    required int id,
    required DateTime sendTime,
    required int senderUsersId,
    required int recipientUsersId,
    required String title,
    required String content,
    DateTime? readTime,
    @Default(0) int hide,
    String? files,
  }) = _Message;
}
