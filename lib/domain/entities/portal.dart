import 'package:freezed_annotation/freezed_annotation.dart';

part 'portal.freezed.dart';

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
