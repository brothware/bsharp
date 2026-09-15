import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/core/network/serial_queue.dart';
import 'package:bsharp/data/data_sources/remote/auth_service.dart';
import 'package:bsharp/data/data_sources/remote/portal_data_source.dart';
import 'package:flutter/foundation.dart';

@immutable
class PortalSession {
  const PortalSession({
    required this.token,
    required this.sid,
    required this.user,
  });

  final String token;
  final String sid;
  final Map<String, dynamic> user;

  String? get messagesToken => user['messagesToken'] as String?;
}

/// Holds one portal session and hands every call the same one.
///
/// The login token authenticates a single call: the `users` view trades it for
/// a `sid`, and that sid authenticates everything afterwards until the server
/// rejects it with [ExpiredSession]. Logging in again throws away the session
/// the previous login opened, so a login is worth making only when there is no
/// session left to use.
class PortalSessionManager {
  PortalSessionManager({
    required this._auth,
    required this._portal,
    required this._school,
    required this._login,
    required this._password,
  });

  final AuthService _auth;
  final PortalDataSource _portal;
  final String _school;
  final String _login;
  final String _password;
  final _queue = SerialQueue();

  PortalSession? _session;

  Future<Result<PortalSession>> ensureSession() => _queue.add(_ensureSession);

  Future<Result<Map<String, dynamic>>> getView({
    required String view,
    required Map<String, String> params,
  }) {
    return _queue.add(() async {
      final opened = await _ensureSession();
      if (opened case Failure(:final failure)) {
        return Result<Map<String, dynamic>>.failure(failure);
      }

      final result = await _getView(
        (opened as Success<PortalSession>).value,
        view,
        params,
      );
      if (result case Failure(failure: ExpiredSession())) {
        return _retryWithNewSession(view, params);
      }
      return result;
    });
  }

  Future<Result<Map<String, dynamic>>> _retryWithNewSession(
    String view,
    Map<String, String> params,
  ) async {
    _session = null;
    final reopened = await _ensureSession();
    if (reopened case Failure(:final failure)) {
      return Result<Map<String, dynamic>>.failure(failure);
    }
    return _getView((reopened as Success<PortalSession>).value, view, params);
  }

  Future<Result<Map<String, dynamic>>> _getView(
    PortalSession session,
    String view,
    Map<String, String> params,
  ) {
    return _portal.getView(
      school: _school,
      token: session.token,
      sid: session.sid,
      view: view,
      params: params,
    );
  }

  Future<Result<PortalSession>> _ensureSession() async {
    final current = _session;
    if (current != null) return Result.success(current);

    final token = await _auth.obtainPortalToken(
      login: _login,
      password: _password,
    );
    if (token case Failure(:final failure)) {
      return Result<PortalSession>.failure(failure);
    }

    final tokenValue = (token as Success<String>).value;
    final user = await _portal.getView(
      school: _school,
      token: tokenValue,
      sid: '',
      view: 'users',
      params: {},
    );
    if (user case Failure(:final failure)) {
      return Result<PortalSession>.failure(failure);
    }

    final userData = (user as Success<Map<String, dynamic>>).value;
    final sid = userData['sid'] as String?;
    if (sid == null || sid.isEmpty) {
      return const Result.failure(
        ExpiredSession(message: 'Portal login returned no session id'),
      );
    }

    final session = PortalSession(token: tokenValue, sid: sid, user: userData);
    _session = session;
    return Result.success(session);
  }
}
