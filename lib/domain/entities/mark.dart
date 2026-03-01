import 'package:freezed_annotation/freezed_annotation.dart';

part 'mark.freezed.dart';

@freezed
abstract class Mark with _$Mark {
  const factory Mark({
    required int id,
    required int markGroupsId,
    int? markScalesId,
    required int pupilUsersId,
    required int teacherUsersId,
    double? markValue,
    String? comments,
    @Default(1) int weight,
    required DateTime getDate,
    DateTime? addTime,
    required int modified,
    int? eventsId,
  }) = _Mark;
}

@freezed
abstract class MarkGroup with _$MarkGroup {
  const factory MarkGroup({
    required int id,
    int? parentId,
    int? parentType,
    int? markGroupGroupsId,
    required int isPattern,
    int? eventTypeTermsId,
    int? markKindsId,
    String? abbreviation,
    String? description,
    required int markType,
    String? markFormat,
    int? markDivisionGroupsId,
    int? markScaleGroupsId,
    required int visibility,
    String? cssStyle,
    required int position,
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
    int? parentId,
    required String name,
    required String abbreviation,
    int? subjectsId,
    required int public,
    int? addByUsersId,
    required int defaultMarkType,
    int? defaultMarkScaleGroupsId,
    int? defaultMarkDivisionGroupsId,
    required int defaultWeight,
    required int position,
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
    double? markValue,
    String? image,
    required int classified,
    required int noCountToAverage,
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
    int? addByUsersId,
    String? markTypes,
    int? markScaleGroupEduId,
    required int isSystem,
    required int isDefault,
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
    int? markDivisionGroupsId,
    required String name,
    int? parentId,
    required int isPattern,
    required int position,
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
