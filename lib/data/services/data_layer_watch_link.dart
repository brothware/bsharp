import 'dart:async';

import 'package:bsharp/domain/entities/account_handoff.dart';
import 'package:bsharp/domain/watch_link.dart';
import 'package:watch_connectivity/watch_connectivity.dart';

const _kindKey = 'kind';
const _versionKey = 'version';
const _accountKind = 'bsharp.account';
const _accountVersion = 1;
const _receivedKind = 'bsharp.account-received';
const _defaultAcknowledgementTimeout = Duration(seconds: 10);

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
  DataLayerWatchLink(
    this._connectivity, {
    this._acknowledgementTimeout = _defaultAcknowledgementTimeout,
  });

  final WatchConnectivityBase _connectivity;
  final Duration _acknowledgementTimeout;

  @override
  Future<bool> hasPairedWatch() => _connectivity.isPaired;

  @override
  Future<bool> hasConnectedCounterpart() => _connectivity.isReachable;

  @override
  Future<bool> sendAccount(AccountHandoff account) async {
    final acknowledged = Completer<bool>();
    final subscription = _connectivity.messageStream.listen(
      (message) {
        if (message[_kindKey] == _receivedKind && !acknowledged.isCompleted) {
          acknowledged.complete(true);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!acknowledged.isCompleted) {
          acknowledged.completeError(error, stackTrace);
        }
      },
    );
    // Listened to before the send, so an error while sending still has a
    // handler instead of escaping as an uncaught one.
    final answer = acknowledged.future.timeout(
      _acknowledgementTimeout,
      onTimeout: () => false,
    );
    try {
      await _connectivity.sendMessage(encodeAccountHandoff(account));
      return await answer;
    } finally {
      await subscription.cancel();
    }
  }

  @override
  Future<void> acknowledgeAccount() => _connectivity.sendMessage({
    _kindKey: _receivedKind,
    _versionKey: _accountVersion,
  });

  @override
  Stream<AccountHandoff> get receivedAccounts => _connectivity.messageStream
      .where((message) => message[_kindKey] == _accountKind)
      .map(decodeAccountHandoff);
}
