import 'package:freezed_annotation/freezed_annotation.dart';

part 'room.freezed.dart';

@freezed
abstract class Room with _$Room {
  const factory Room({
    required int id,
    int? patronsId,
    required String name,
    String? description,
  }) = _Room;
}
