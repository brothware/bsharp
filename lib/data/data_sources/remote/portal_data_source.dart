import 'package:bsharp/core/error/result.dart';
import 'package:dio/dio.dart';

/// The host the portal session was opened from, which the portal expects back
/// on every call it serves.
const _callerHost = 'mobireg.pl';

class PortalDataSource {
  PortalDataSource({required this._client});

  final Dio _client;

  Future<Result<Map<String, dynamic>>> getView({
    required String school,
    required String token,
    required String sid,
    required String view,
    required Map<String, String> params,
  }) async {
    return _post({
      'school': school,
      'token': token,
      'sid': sid,
      'callerHost': _callerHost,
      'view': view,
      ...params,
    });
  }

  Future<Result<Map<String, dynamic>>> mutate({
    required String school,
    required String token,
    required String sid,
    required String data,
  }) async {
    return _post({
      'school': school,
      'token': token,
      'sid': sid,
      'callerHost': _callerHost,
      'data': data,
    });
  }

  Future<Result<Map<String, dynamic>>> _post(Map<String, String> data) async {
    try {
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
}
