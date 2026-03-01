import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:bsharp/domain/entities/sync_action.dart';

part 'student.freezed.dart';

@freezed
abstract class Student with _$Student {
  const factory Student({
    required int id,
    required int usersEduId,
    required String name,
    required String surname,
    required Sex sex,
    String? phone,
    String? pin,
  }) = _Student;
}
