import 'dart:ui';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'portal.freezed.dart';

@freezed
abstract class PortalUser with _$PortalUser {
  const factory PortalUser({
    required String login,
    required String name,
    required String surname,
    required List<PortalPupil> pupils,
    String? messagesToken,
  }) = _PortalUser;
}

@freezed
abstract class PortalPupil with _$PortalPupil {
  const factory PortalPupil({
    required int id,
    required String name,
    required String surname,
    required String className,
  }) = _PortalPupil;
}

@freezed
abstract class PortalTimetableEvent with _$PortalTimetableEvent {
  const factory PortalTimetableEvent({
    required int id,
    required DateTime dateTimeFrom,
    required DateTime dateTimeTo,
    required String subjectName,
    Color? bgColor,
    String? attendanceLabel,
    required bool isLocked,
    required bool isCyclic,
    required bool isCanceled,
    required bool substitution,
    String? room,
    String? title,
    required List<String> teachers,
    required bool hasTest,
    required List<dynamic> tests,
    int? relatedEventId,
    required List<int> relatedEventsId,
  }) = _PortalTimetableEvent;
}

@freezed
abstract class PortalMark with _$PortalMark {
  const factory PortalMark({
    required int id,
    required int subjectId,
    required String kindLabel,
    required String value,
    required int markGroupId,
    required int parentMarkGroupId,
    required String date,
    String? bgColor,
    required int weight,
    String? description,
    String? comments,
  }) = _PortalMark;
}

@freezed
abstract class PortalAttendanceSummary with _$PortalAttendanceSummary {
  const factory PortalAttendanceSummary({
    required double percent,
    required List<PortalAttendanceTypeCount> types,
  }) = _PortalAttendanceSummary;
}

@freezed
abstract class PortalAttendanceTypeCount with _$PortalAttendanceTypeCount {
  const factory PortalAttendanceTypeCount({
    required String label,
    required int count,
  }) = _PortalAttendanceTypeCount;
}

@freezed
abstract class PortalSubject with _$PortalSubject {
  const factory PortalSubject({
    required int id,
    required String name,
  }) = _PortalSubject;
}

@freezed
abstract class PortalTerm with _$PortalTerm {
  const factory PortalTerm({
    required int id,
    required String name,
    required String startDate,
    required String endDate,
  }) = _PortalTerm;
}

@freezed
abstract class PortalBulletin with _$PortalBulletin {
  const factory PortalBulletin({
    required int id,
    required String title,
    required String content,
    required String date,
    required String author,
    required bool isRead,
  }) = _PortalBulletin;
}

@freezed
abstract class PortalTest with _$PortalTest {
  const factory PortalTest({
    required int id,
    required String subjectName,
    required String date,
    String? title,
    String? description,
  }) = _PortalTest;
}

@freezed
abstract class PortalReprimand with _$PortalReprimand {
  const factory PortalReprimand({
    required int id,
    required String date,
    required String teacherName,
    required String content,
    required int type,
  }) = _PortalReprimand;
}

@freezed
abstract class PortalHomework with _$PortalHomework {
  const factory PortalHomework({
    required int id,
    required String subjectName,
    required String date,
    required String dueDate,
    required String content,
  }) = _PortalHomework;
}

@freezed
abstract class PortalChangelog with _$PortalChangelog {
  const factory PortalChangelog({
    required String type,
    required String dateTime,
    required String subjectName,
    required String user,
    required String newName,
    @Default('') String newAdditionalInfo,
    @Default('') String action,
  }) = _PortalChangelog;
}
