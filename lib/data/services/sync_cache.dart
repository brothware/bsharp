import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SyncCache {
  SyncCache(this._prefs) {
    _removeLegacyKeys();
  }

  final SharedPreferences _prefs;

  static const _legacySyncDataKey = 'cache_sync_data';
  static const _legacyPortalPrefix = 'cache_portal_';
  static const _messagesPrefix = 'cache_messages_';
  static const _viewPrefix = 'mobireg_view_';

  void _removeLegacyKeys() {
    _prefs
        .getKeys()
        .where(
          (k) => k == _legacySyncDataKey || k.startsWith(_legacyPortalPrefix),
        )
        .toList()
        .forEach(_prefs.remove);
  }

  void saveMessages(String folder, List<dynamic> data) {
    unawaited(
      _prefs.setString('$_messagesPrefix$folder', jsonEncode(data)),
    );
  }

  List<dynamic>? loadMessages(String folder) {
    final raw = _prefs.getString('$_messagesPrefix$folder');
    if (raw == null) return null;
    return jsonDecode(raw) as List<dynamic>;
  }

  void saveView(String key, Object data) {
    unawaited(_prefs.setString('$_viewPrefix$key', jsonEncode(data)));
  }

  Object? loadView(String key) {
    final raw = _prefs.getString('$_viewPrefix$key');
    if (raw == null) {
      return null;
    }
    return jsonDecode(raw);
  }

  void clear() {
    _prefs
        .getKeys()
        .where(
          (k) => k.startsWith(_messagesPrefix) || k.startsWith(_viewPrefix),
        )
        .toList()
        .forEach(_prefs.remove);
  }
}
