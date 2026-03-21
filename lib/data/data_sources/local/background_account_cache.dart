import 'dart:convert';

import 'package:bsharp/data/data_sources/local/account_storage.dart';
import 'package:bsharp/domain/entities/provider_account.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackgroundAccountCache {
  BackgroundAccountCache(this._prefs);

  final SharedPreferences _prefs;

  static const _accountsKey = 'bg_cache_accounts';
  static const _activeSelectionKey = 'bg_cache_active_selection';

  Future<void> syncFrom(AccountStorage storage) async {
    final accounts = await storage.getAccounts();
    final selection = await storage.getActiveSelection();

    await _prefs.setString(
      _accountsKey,
      jsonEncode(accounts.map((a) => a.toJson()).toList()),
    );

    if (selection != null) {
      await _prefs.setString(
        _activeSelectionKey,
        jsonEncode({
          'accountId': selection.accountId,
          'studentId': selection.studentId,
        }),
      );
    } else {
      await _prefs.remove(_activeSelectionKey);
    }
  }

  List<ProviderAccount> getAccounts() {
    final raw = _prefs.getString(_accountsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .cast<Map<String, dynamic>>()
        .map(ProviderAccount.fromJson)
        .toList();
  }

  ActiveSelection? getActiveSelection() {
    final raw = _prefs.getString(_activeSelectionKey);
    if (raw == null) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return ActiveSelection(
      accountId: map['accountId'] as String,
      studentId: map['studentId'] as int,
    );
  }

  Future<void> clear() async {
    await _prefs.remove(_accountsKey);
    await _prefs.remove(_activeSelectionKey);
  }
}
