import 'package:freezed_annotation/freezed_annotation.dart';

part 'room.freezed.dart';

@freezed
abstract class Room with _$Room {
  const factory Room({
    required int id,
    required String name,
    int? patronsId,
    String? description,
  }) = _Room;
}
