import 'package:freezed_annotation/freezed_annotation.dart';

part 'event.freezed.dart';

@freezed
abstract class Event with _$Event {
  const factory Event({
    required int id,
    String? name,
    required DateTime date,
    required int number,
    required String startTime,
    required String endTime,
    int? roomsId,
    required int eventTypesId,
    required int status,
    required int substitution,
    required int type,
    required int attr,
    int? termsId,
    int? lessonGroupsId,
    required int locked,
  }) = _Event;
}

@freezed
abstract class EventType with _$EventType {
  const factory EventType({
    required int id,
    int? subjectsId,
    required int teachingLevel,
    required int substitution,
  }) = _EventType;
}

@freezed
abstract class EventTypeTeacher with _$EventTypeTeacher {
  const factory EventTypeTeacher({
    required int id,
    required int teachersId,
    required int eventTypesId,
  }) = _EventTypeTeacher;
}

@freezed
abstract class EventTypeGroup with _$EventTypeGroup {
  const factory EventTypeGroup({
    required int id,
    required int groupsId,
    required int eventTypesId,
  }) = _EventTypeGroup;
}

@freezed
abstract class EventTypeTerm with _$EventTypeTerm {
  const factory EventTypeTerm({
    required int id,
    required int termsId,
    required int eventTypesId,
  }) = _EventTypeTerm;
}

@freezed
abstract class EventSubject with _$EventSubject {
  const factory EventSubject({
    required int id,
    required int eventsId,
    required String content,
    DateTime? addTime,
  }) = _EventSubject;
}

@freezed
abstract class EventIssue with _$EventIssue {
  const factory EventIssue({
    required int id,
    required int eventsId,
    required int eventTypesId,
    required int issuesId,
  }) = _EventIssue;
}

@freezed
abstract class EventEvent with _$EventEvent {
  const factory EventEvent({
    required int id,
    required int events1Id,
    required int events2Id,
  }) = _EventEvent;
}

@freezed
abstract class EventTypeSchedule with _$EventTypeSchedule {
  const factory EventTypeSchedule({
    required int id,
    required int eventTypesId,
    required int schedulesId,
    required String name,
    required String number,
  }) = _EventTypeSchedule;
}
