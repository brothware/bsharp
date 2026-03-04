import 'package:bsharp/core/error/result.dart';
import 'package:dio/dio.dart';

class PortalDataSource {
  PortalDataSource({required Dio client}) : _client = client;

  final Dio _client;

  Future<Result<Map<String, dynamic>>> getView({
    required String school,
    required String token,
    required String view,
    required Map<String, String> params,
  }) async {
    try {
      final data = <String, String>{
        'school': school,
        'token': token,
        'view': view,
        ...params,
      };

      final response = await _client.post<Map<String, dynamic>>(
        '/api.php',
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

  Future<Result<Map<String, dynamic>>> mutate({
    required String school,
    required String token,
    required String data,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/api.php',
        data: {'school': school, 'token': token, 'data': data},
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
