import 'package:freezed_annotation/freezed_annotation.dart';

part 'organization.freezed.dart';

@freezed
abstract class StudentGroup with _$StudentGroup {
  const factory StudentGroup({
    required int id,
    required int studentsId,
    required int groupsId,
    required int number,
    DateTime? strikeOffTime,
    String? strikeOffReason,
  }) = _StudentGroup;
}

@freezed
abstract class GroupEducator with _$GroupEducator {
  const factory GroupEducator({
    required int id,
    required int groupsId,
    required int teachersEducatorId,
  }) = _GroupEducator;
}

@freezed
abstract class GroupTerm with _$GroupTerm {
  const factory GroupTerm({
    required int id,
    required int groupsId,
    required int termsId,
  }) = _GroupTerm;
}
