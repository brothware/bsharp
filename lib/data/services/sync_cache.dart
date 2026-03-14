import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SyncCache {
  SyncCache(this._prefs);

  final SharedPreferences _prefs;

  static const _syncDataKey = 'cache_sync_data';
  static const _portalPrefix = 'cache_portal_';
  static const _messagesPrefix = 'cache_messages_';

  void saveSyncData(Map<String, dynamic> data) {
    unawaited(_prefs.setString(_syncDataKey, jsonEncode(data)));
  }

  Map<String, dynamic>? loadSyncData() {
    final raw = _prefs.getString(_syncDataKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  void savePortalView(String view, List<dynamic> items) {
    unawaited(_prefs.setString('$_portalPrefix$view', jsonEncode(items)));
  }

  List<dynamic>? loadPortalView(String view) {
    final raw = _prefs.getString('$_portalPrefix$view');
    if (raw == null) return null;
    return jsonDecode(raw) as List<dynamic>;
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

  void clear() {
    _prefs
        .getKeys()
        .where(
          (k) =>
              k == _syncDataKey ||
              k.startsWith(_portalPrefix) ||
              k.startsWith(_messagesPrefix),
        )
        .toList()
        .forEach(_prefs.remove);
  }
}
