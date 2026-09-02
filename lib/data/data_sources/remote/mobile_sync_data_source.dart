import 'package:bsharp/core/error/result.dart';
import 'package:dio/dio.dart';

class MobileSyncDataSource {
  MobileSyncDataSource({required this._client});

  final Dio _client;

  Future<Result<Map<String, dynamic>>> getSettings() async {
    return _post({'view': 'Settings'});
  }

  Future<Result<Map<String, dynamic>>> getStudents() async {
    return _post({'view': 'ParentStudents'});
  }

  Future<Result<Map<String, dynamic>>> fullSync({
    required int studentId,
    required String startDate,
    required String endDate,
  }) async {
    return _post({
      'start_date': startDate,
      'end_date': endDate,
      'get_all_mark_groups': '1',
      'student_id': studentId.toString(),
    });
  }

  Future<Result<Map<String, dynamic>>> diffSync({
    required int studentId,
    required String startDate,
    required String endDate,
    required String lastModificationTime,
    required String lastEndDate,
  }) async {
    return _post({
      'start_date': startDate,
      'end_date': endDate,
      'last_end_date': lastEndDate,
      'lmt': lastModificationTime,
      'get_all_mark_groups': '1',
      'student_id': studentId.toString(),
    });
  }

  Future<Result<Map<String, dynamic>>> registerFcmToken({
    required String token,
  }) async {
    return _post({'view': 'ParentStudents', 'token': token});
  }

  Future<Result<Map<String, dynamic>>> _post(Map<String, dynamic> data) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/njson.php',
        data: data,
      );

      if (response.data == null) {
        return const Result.failure(NoData(message: 'Empty response'));
      }

      return Result.success(response.data!);
    } on DioException catch (e) {
      if (e.error is AppFailure) {
        return Result.failure(e.error! as AppFailure);
      }
      return Result.failure(UnknownFailure(message: e.message));
    }
  }
}
