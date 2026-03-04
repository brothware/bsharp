import 'package:freezed_annotation/freezed_annotation.dart';

part 'mark.freezed.dart';

@freezed
abstract class Mark with _$Mark {
  const factory Mark({
    required int id,
    required int markGroupsId,
    required int pupilUsersId,
    required int teacherUsersId,
    required DateTime getDate,
    required int modified,
    int? markScalesId,
    double? markValue,
    String? comments,
    @Default(1) int weight,
    DateTime? addTime,
    int? eventsId,
  }) = _Mark;
}

@freezed
abstract class MarkGroup with _$MarkGroup {
  const factory MarkGroup({
    required int id,
    required int isPattern,
    required int markType,
    required int visibility,
    required int position,
    int? parentId,
    int? parentType,
    int? markGroupGroupsId,
    int? eventTypeTermsId,
    int? markKindsId,
    String? abbreviation,
    String? description,
    String? markFormat,
    int? markDivisionGroupsId,
    int? markScaleGroupsId,
    String? cssStyle,
    @Default(1) int weight,
    double? markValueRangeMin,
    double? markValueRangeMax,
    double? precision,
    int? addByUsersId,
  }) = _MarkGroup;
}

@freezed
abstract class MarkKind with _$MarkKind {
  const factory MarkKind({
    required int id,
    required String name,
    required String abbreviation,
    required int public,
    required int defaultMarkType,
    required int defaultWeight,
    required int position,
    int? parentId,
    int? subjectsId,
    int? addByUsersId,
    int? defaultMarkScaleGroupsId,
    int? defaultMarkDivisionGroupsId,
    String? cssStyle,
  }) = _MarkKind;
}

@freezed
abstract class MarkScale with _$MarkScale {
  const factory MarkScale({
    required int id,
    required int markScaleGroupsId,
    required String abbreviation,
    required String name,
    required int classified,
    required int noCountToAverage,
    double? markValue,
    String? image,
    String? cssStyle,
    int? markScaleEduId,
  }) = _MarkScale;
}

@freezed
abstract class MarkScaleGroup with _$MarkScaleGroup {
  const factory MarkScaleGroup({
    required int id,
    required String name,
    required int public,
    required int isSystem,
    required int isDefault,
    int? addByUsersId,
    String? markTypes,
    int? markScaleGroupEduId,
  }) = _MarkScaleGroup;
}

@freezed
abstract class MarkDivisionGroup with _$MarkDivisionGroup {
  const factory MarkDivisionGroup({
    required int id,
    required int markScaleGroupsId,
    required String name,
    required int type,
    required int public,
    double? rangeMin,
    double? rangeMax,
    double? precision,
    int? addByUsersId,
    int? markDivisionGroupEduId,
    double? rangeMaxToDisplay,
  }) = _MarkDivisionGroup;
}

@freezed
abstract class MarkGroupGroup with _$MarkGroupGroup {
  const factory MarkGroupGroup({
    required int id,
    required String name,
    required int isPattern,
    required int position,
    int? markDivisionGroupsId,
    int? parentId,
    @Default(1) int weight,
  }) = _MarkGroupGroup;
}

@freezed
abstract class MarkGroupIssue with _$MarkGroupIssue {
  const factory MarkGroupIssue({
    required int id,
    required int markGroupsId,
    required int issuesId,
  }) = _MarkGroupIssue;
}
