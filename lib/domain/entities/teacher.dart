import 'package:freezed_annotation/freezed_annotation.dart';

part 'teacher.freezed.dart';

@freezed
abstract class Teacher with _$Teacher {
  const factory Teacher({
    required int id,
    required String login,
    required String name,
    required String surname,
    required int userType,
    int? usersEduId,
    String? phone,
    String? pin,
  }) = _Teacher;
}
