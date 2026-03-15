import 'package:freezed_annotation/freezed_annotation.dart';

part 'resolved_grade.freezed.dart';

@freezed
abstract class ResolvedGrade with _$ResolvedGrade {
  const factory ResolvedGrade({
    required int id,
    required String subjectName,
    required String categoryName,
    required String displayValue,
    required DateTime date,
    double? effectiveValue,
    @Default(true) bool countsToAverage,
    @Default(1) int weight,
    String? teacherName,
    String? comment,
    double? markMax,
    int? termId,
    int? subjectId,
  }) = _ResolvedGrade;
}
