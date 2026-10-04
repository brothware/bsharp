import 'package:bsharp/data/data_sources/remote/app_api_session.dart';
import 'package:flutter/foundation.dart';

class AppApiSessionRegistry {
  static final shared = AppApiSessionRegistry();

  final Map<String, _RegisteredSession> _sessions = {};

  AppApiSession sessionFor({
    required String school,
    required String login,
    required String password,
    required AppApiSession Function() create,
  }) {
    final key = '$school/$login';
    final existing = _sessions[key];
    if (existing != null && existing.password == password) {
      return existing.session;
    }
    final session = create();
    _sessions[key] = _RegisteredSession(password: password, session: session);
    return session;
  }
}

@immutable
class _RegisteredSession {
  const _RegisteredSession({required this.password, required this.session});

  final String password;
  final AppApiSession session;
}
