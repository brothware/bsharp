import 'dart:convert';

import 'package:bsharp/data/data_sources/local/key_value_store.dart';
import 'package:bsharp/data/data_sources/local/key_value_store_native.dart'
    if (dart.library.js_interop) 'package:bsharp/data/data_sources/local/key_value_store_web.dart'
    as platform;
import 'package:bsharp/domain/entities/provider_account.dart';

class AccountStorage {
  AccountStorage({KeyValueStore? store})
    : _store = store ?? platform.createDefaultStore();

  final KeyValueStore _store;

  static const _accountsKey = 'provider_accounts';
  static const _activeStudentKey = 'active_student';

  Future<List<ProviderAccount>> getAccounts() async {
    final raw = await _store.read(key: _accountsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .cast<Map<String, dynamic>>()
        .map(ProviderAccount.fromJson)
        .toList();
  }

  Future<void> saveAccounts(List<ProviderAccount> accounts) async {
    final json = jsonEncode(accounts.map((a) => a.toJson()).toList());
    await _store.write(key: _accountsKey, value: json);
  }

  Future<void> addAccount(ProviderAccount account) async {
    final accounts = await getAccounts();
    accounts.add(account);
    await saveAccounts(accounts);
  }

  Future<void> updateAccount(ProviderAccount account) async {
    final accounts = await getAccounts();
    final index = accounts.indexWhere((a) => a.id == account.id);
    if (index != -1) {
      accounts[index] = account;
      await saveAccounts(accounts);
    }
  }

  Future<void> removeAccount(String accountId) async {
    final accounts = await getAccounts();
    accounts.removeWhere((a) => a.id == accountId);
    await saveAccounts(accounts);

    final active = await getActiveSelection();
    if (active != null && active.accountId == accountId) {
      await clearActiveSelection();
    }
  }

  Future<ActiveSelection?> getActiveSelection() async {
    final raw = await _store.read(key: _activeStudentKey);
    if (raw == null) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return ActiveSelection(
      accountId: map['accountId'] as String,
      studentId: map['studentId'] as int,
    );
  }

  Future<void> saveActiveSelection(ActiveSelection selection) async {
    final json = jsonEncode({
      'accountId': selection.accountId,
      'studentId': selection.studentId,
    });
    await _store.write(key: _activeStudentKey, value: json);
  }

  Future<void> clearActiveSelection() => _store.delete(key: _activeStudentKey);

  Future<bool> hasActiveSelection() async {
    final selection = await getActiveSelection();
    return selection != null;
  }

  Future<void> clearAll() => _store.deleteAll();
}

class ActiveSelection {
  const ActiveSelection({
    required this.accountId,
    required this.studentId,
  });

  final String accountId;
  final int studentId;
}
