import 'package:freezed_annotation/freezed_annotation.dart';

part 'teacher.freezed.dart';

@freezed
abstract class Teacher with _$Teacher {
  const factory Teacher({
    required int id,
    required String login,
    int? usersEduId,
    required String name,
    required String surname,
    String? phone,
    String? pin,
    required int userType,
  }) = _Teacher;
}
