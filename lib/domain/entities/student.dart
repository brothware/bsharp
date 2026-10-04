import 'package:freezed_annotation/freezed_annotation.dart';

part 'student.freezed.dart';

@freezed
abstract class Student with _$Student {
  const factory Student({
    required int id,
    required String name,
    required String surname,
    String? phone,
    String? pin,
  }) = _Student;
}
