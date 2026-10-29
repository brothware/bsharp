import 'dart:async';

import 'package:bsharp/domain/entities/account_handoff.dart';
import 'package:bsharp/domain/watch_link.dart';
import 'package:watch_connectivity/watch_connectivity.dart';

const _kindKey = 'kind';
const _versionKey = 'version';
const _accountKind = 'bsharp.account';
const _accountVersion = 1;

class UnsupportedHandoffVersion implements Exception {
  const UnsupportedHandoffVersion(this.version);

  final Object? version;

  @override
  String toString() =>
      'UnsupportedHandoffVersion: account sent as version $version, this app '
      'reads $_accountVersion';
}

Map<String, dynamic> encodeAccountHandoff(AccountHandoff account) => {
  _kindKey: _accountKind,
  _versionKey: _accountVersion,
  'providerType': account.providerType,
  'school': account.school,
  'login': account.login,
  'password': account.password,
};

AccountHandoff decodeAccountHandoff(Map<String, dynamic> message) {
  final version = message[_versionKey];
  if (version != _accountVersion) {
    throw UnsupportedHandoffVersion(version);
  }
  String field(String key) => switch (message[key]) {
    final String value when value.isNotEmpty => value,
    _ => throw FormatException('Account handoff has no "$key"'),
  };
  return AccountHandoff(
    providerType: field('providerType'),
    school: field('school'),
    login: field('login'),
    password: field('password'),
  );
}

class DataLayerWatchLink implements WatchLink {
  DataLayerWatchLink(this._connectivity);

  final WatchConnectivityBase _connectivity;

  @override
  Future<bool> hasConnectedCounterpart() => _connectivity.isReachable;

  @override
  Future<void> sendAccount(AccountHandoff account) =>
      _connectivity.sendMessage(encodeAccountHandoff(account));

  @override
  Stream<AccountHandoff> get receivedAccounts => _connectivity.messageStream
      .where((message) => message[_kindKey] == _accountKind)
      .map(decodeAccountHandoff);
}
