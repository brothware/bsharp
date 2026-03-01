import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/domain/entities/portal.dart';

abstract interface class PortalRepository {
  Future<Result<PortalUser>> getUser();

  Future<Result<List<PortalTimetableEvent>>> getTimetable({
    required int pupilId,
    required DateTime dateFrom,
    required DateTime dateTo,
  });

  Future<Result<List<PortalMark>>> getMarks({
    required int pupilId,
    required int termId,
  });

  Future<Result<PortalAttendanceSummary>> getAttendance({
    required int pupilId,
    required DateTime dateFrom,
    required DateTime dateTo,
  });

  Future<Result<List<PortalSubject>>> getSubjects({required int pupilId});

  Future<Result<List<PortalTerm>>> getTerms({required int pupilId});

  Future<Result<List<PortalTest>>> getTests({
    required int pupilId,
    required DateTime dateFrom,
    required DateTime dateTo,
  });

  Future<Result<List<PortalReprimand>>> getReprimands({
    required int pupilId,
    required DateTime dateFrom,
    required DateTime dateTo,
    int? type,
  });

  Future<Result<List<PortalHomework>>> getHomeworks({
    required int pupilId,
    required DateTime dateFrom,
    required DateTime dateTo,
  });

  Future<Result<List<PortalBulletin>>> getBulletins({
    required int pupilId,
    required DateTime dateFrom,
    required DateTime dateTo,
  });

  Future<Result<PortalBulletin>> getBulletin({
    required int pupilId,
    required int bulletinId,
  });

  Future<Result<List<PortalChangelog>>> getChangelog({
    required int pupilId,
    DateTime? dateFrom,
    DateTime? dateTo,
  });

  Future<Result<void>> markBulletinRead(int bulletinId);

  Future<Result<void>> acceptRodo();

  Future<Result<void>> updateEmail(String newEmail);

  Future<Result<void>> changePassword({
    required String oldMd5,
    required String newMd5,
  });

  Future<Result<void>> setContactConsent({required bool allow});
}
