import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:bsharp/domain/entities/sync_action.dart';

part 'attendance.freezed.dart';

@freezed
abstract class Attendance with _$Attendance {
  const factory Attendance({
    required int id,
    required int eventsId,
    required int studentsId,
    required int typesId,
  }) = _Attendance;
}

@freezed
abstract class AttendanceType with _$AttendanceType {
  const factory AttendanceType({
    required int id,
    required String name,
    required String abbr,
    String? style,
    required AttendanceCountAs countAs,
    required AttendanceExcuseStatus excuseStatus,
  }) = _AttendanceType;
}
