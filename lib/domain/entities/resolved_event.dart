import 'package:freezed_annotation/freezed_annotation.dart';

part 'resolved_event.freezed.dart';

@freezed
abstract class ResolvedEvent with _$ResolvedEvent {
  const factory ResolvedEvent({
    required int id,
    required DateTime date,
    required int number,
    required String startTime,
    required String endTime,
    String? subjectName,
    String? teacherName,
    String? roomName,
    String? topic,
    int? subjectId,
    @Default(false) bool isCancelled,
    @Default(false) bool isSubstitution,
    @Default(false) bool isLocked,
    String? originalSubjectName,
    String? originalTeacherName,
    @Default([]) List<int> replacedLessonNumbers,
    @Default(false) bool isReplaced,
    int? replacedByEventId,
    String? eventName,
  }) = _ResolvedEvent;
}
