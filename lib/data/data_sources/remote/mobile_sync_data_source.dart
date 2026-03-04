import 'package:bsharp/core/error/result.dart';
import 'package:dio/dio.dart';

class MobileSyncDataSource {
  MobileSyncDataSource({required Dio client}) : _client = client;

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
      'student_id': studentId.toString(),
      'start_date': startDate,
      'end_date': endDate,
      'get_all_mark_groups': '1',
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
      'student_id': studentId.toString(),
      'start_date': startDate,
      'end_date': endDate,
      'lmt': lastModificationTime,
      'last_end_date': lastEndDate,
      'get_all_mark_groups': '1',
    });
  }

  Future<Result<Map<String, dynamic>>> _post(Map<String, dynamic> data) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/njson.php',
        data: data,
        options: Options(contentType: Headers.formUrlEncodedContentType),
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
