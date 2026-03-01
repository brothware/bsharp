import 'dart:io';

import 'package:dio/dio.dart';
import 'package:bsharp/core/error/result.dart';

class ErrorMappingInterceptor extends Interceptor {
  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    final data = response.data;
    if (data is Map<String, dynamic> && data.containsKey('errno')) {
      final errno = data['errno'] as int;
      final message = data['message'] as String?;
      handler.reject(
        DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: AppFailure.fromErrno(errno, message),
          type: DioExceptionType.badResponse,
        ),
      );
      return;
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.error is AppFailure) {
      handler.next(err);
      return;
    }

    final AppFailure failure;
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      failure = const ConnectionTimeout();
    } else if (err.error is SocketException ||
        err.type == DioExceptionType.connectionError) {
      failure = const NoConnection();
    } else {
      failure = UnknownFailure(message: err.message);
    }

    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        error: failure,
        type: err.type,
      ),
    );
  }
}
