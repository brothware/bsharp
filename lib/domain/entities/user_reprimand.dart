import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:bsharp/domain/entities/sync_action.dart';

part 'user_reprimand.freezed.dart';

@freezed
abstract class UserReprimand with _$UserReprimand {
  const factory UserReprimand({
    required int id,
    required int studentsId,
    required int teachersId,
    required ReprimandKind kind,
    required DateTime getDate,
    required String content,
    DateTime? addTime,
    required int status,
  }) = _UserReprimand;
}
