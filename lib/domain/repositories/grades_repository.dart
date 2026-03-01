import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/domain/entities/mark.dart';
import 'package:bsharp/domain/entities/portal.dart';

abstract interface class GradesRepository {
  Stream<List<Mark>> watchGradesForStudent(int studentId);

  Stream<List<MarkGroup>> watchMarkGroups();

  Stream<List<MarkScale>> watchMarkScales();

  Future<Result<List<PortalMark>>> fetchPortalMarks({
    required int pupilId,
    required int termId,
  });
}
