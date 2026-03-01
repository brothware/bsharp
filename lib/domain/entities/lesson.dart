import 'package:freezed_annotation/freezed_annotation.dart';

part 'lesson.freezed.dart';

@freezed
abstract class Lesson with _$Lesson {
  const factory Lesson({
    required int id,
    required int lessonGroupsId,
    required int lessonNumber,
    required String startTime,
    required String endTime,
  }) = _Lesson;
}

@freezed
abstract class LessonGroup with _$LessonGroup {
  const factory LessonGroup({
    required int id,
    required String name,
    required int selected,
  }) = _LessonGroup;
}
