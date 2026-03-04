import 'package:bsharp/domain/entities/sync_action.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

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
    required int status,
    DateTime? addTime,
  }) = _UserReprimand;
}
