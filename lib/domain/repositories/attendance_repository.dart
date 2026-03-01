import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/domain/entities/attendance.dart';
import 'package:bsharp/domain/entities/portal.dart';

abstract interface class AttendanceRepository {
  Stream<List<Attendance>> watchAttendanceForStudent(int studentId);

  Stream<List<AttendanceType>> watchAttendanceTypes();

  Future<Result<PortalAttendanceSummary>> fetchAttendanceSummary({
    required int pupilId,
    required DateTime dateFrom,
    required DateTime dateTo,
  });
}
