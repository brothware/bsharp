import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/core/network/serial_queue.dart';
import 'package:bsharp/data/data_sources/remote/app_api_data_source.dart';

class AppApiSession {
  AppApiSession({
    required this._api,
    required this._login,
    required this._password,
  });

  final AppApiDataSource _api;
  final String _login;
  final String _password;
  final _queue = SerialQueue();

  String? _jwt;
  Map<String, dynamic>? _account;

  Future<Result<ViewPayload>> getView(
    String view, {
    Map<String, String> params = const {},
  }) {
    return _queue.add(() => _getViewWithRelogin(view, params));
  }

  Future<Result<Map<String, dynamic>>> account() {
    return _queue.add(() async {
      final cached = _account;
      if (cached != null) {
        return Result.success(cached);
      }
      final result = await _getViewWithRelogin('users', const {});
      if (result case Failure(:final failure)) {
        return Result<Map<String, dynamic>>.failure(failure);
      }
      final data = (result as Success<ViewPayload>).value.data;
      if (data is! Map<String, dynamic>) {
        throw FormatException('View users answered a non-object', data);
      }
      _account = data;
      return Result.success(data);
    });
  }

  void forgetAccount() {
    _account = null;
  }

  Future<Result<ViewPayload>> _getViewWithRelogin(
    String view,
    Map<String, String> params,
  ) async {
    final first = await _getViewOnce(view, params);
    if (first case Failure(failure: SessionExpired())) {
      _jwt = null;
      _account = null;
      return _getViewOnce(view, params);
    }
    return first;
  }

  Future<Result<ViewPayload>> _getViewOnce(
    String view,
    Map<String, String> params,
  ) async {
    final jwt = await _ensureJwt();
    if (jwt case Failure(:final failure)) {
      return Result<ViewPayload>.failure(failure);
    }
    return _api.getView(
      jwt: (jwt as Success<String>).value,
      view: view,
      params: params,
    );
  }

  Future<Result<String>> _ensureJwt() async {
    final current = _jwt;
    if (current != null) {
      return Result.success(current);
    }
    final result = await _api.login(login: _login, password: _password);
    if (result case Success(:final value)) {
      _jwt = value;
    }
    return result;
  }
}
