import 'dart:async';

import 'package:bsharp/data/services/data_layer_watch_link.dart';
import 'package:bsharp/domain/entities/account_handoff.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watch_connectivity/watch_connectivity.dart';

class _Nodes {
  bool isReachable = true;
  bool isPaired = true;
}

class _FakeConnectivity implements WatchConnectivityBase {
  final sent = <Map<String, dynamic>>[];
  final incoming = StreamController<Map<String, dynamic>>.broadcast();
  final nodes = _Nodes();

  @override
  Stream<Map<String, dynamic>> get messageStream => incoming.stream;

  @override
  Future<bool> get isReachable async => nodes.isReachable;

  @override
  Future<bool> get isPaired async => nodes.isPaired;

  @override
  Future<void> sendMessage(Map<String, dynamic> message) async {
    sent.add(message);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _account = AccountHandoff(
  providerType: 'mobireg',
  school: 'osm-wroclaw',
  login: 'parent',
  password: 'secret',
);

void main() {
  late _FakeConnectivity connectivity;
  late DataLayerWatchLink link;

  setUp(() {
    connectivity = _FakeConnectivity();
    link = DataLayerWatchLink(
      connectivity,
      acknowledgementTimeout: const Duration(milliseconds: 50),
    );
  });

  tearDown(() => connectivity.incoming.close());

  test('an account sent from the phone arrives on the watch whole', () async {
    final delivered = link.sendAccount(_account);
    await pumpEventQueue();
    final received = link.receivedAccounts.first;

    connectivity.incoming.add(connectivity.sent.single);

    expect(await received, _account);
    await delivered;
  });

  test('reading an account does not answer for the screen', () async {
    final received = link.receivedAccounts.first;

    connectivity.incoming.add(encodeAccountHandoff(_account));
    await received;

    expect(
      connectivity.sent,
      isEmpty,
      reason: 'the screen may still ignore or refuse it',
    );
  });

  test('the watch acknowledges an account the screen accepted', () async {
    await link.acknowledgeAccount();

    expect(connectivity.sent.single['kind'], 'bsharp.account-received');
  });

  test('a stream error while sending reaches the caller', () async {
    final sending = link.sendAccount(_account);
    connectivity.incoming.addError(PlatformException(code: 'node_lost'));

    await expectLater(sending, throwsA(isA<PlatformException>()));
  });

  test('a send that times out stops listening for its answer', () async {
    expect(await link.sendAccount(_account), isFalse);

    expect(
      connectivity.incoming.hasListener,
      isFalse,
      reason: 'a late answer would be credited to the next send',
    );
  });

  test('the phone hears the acknowledgement and reports delivery', () async {
    final delivered = link.sendAccount(_account);
    await pumpEventQueue();

    connectivity.incoming.add({
      'kind': 'bsharp.account-received',
      'version': 1,
    });

    expect(await delivered, isTrue);
  });

  test('with no acknowledgement the phone reports nothing delivered', () async {
    expect(await link.sendAccount(_account), isFalse);
  });

  test('the counterpart is connected when a node is reachable', () async {
    expect(await link.hasConnectedCounterpart(), isTrue);

    connectivity.nodes.isReachable = false;

    expect(await link.hasConnectedCounterpart(), isFalse);
  });

  test('a phone with no watch app has no paired watch', () async {
    expect(await link.hasPairedWatch(), isTrue);

    connectivity.nodes.isPaired = false;

    expect(await link.hasPairedWatch(), isFalse);
  });

  test('messages of another kind are not accounts', () async {
    final received = <AccountHandoff>[];
    final subscription = link.receivedAccounts.listen(received.add);

    connectivity.incoming.add({'kind': 'bsharp.snapshot', 'version': 1});
    await pumpEventQueue();

    expect(received, isEmpty);
    await subscription.cancel();
  });

  test('a malformed account message is reported, not dropped', () async {
    final errors = <Object>[];
    final subscription = link.receivedAccounts.listen(
      (_) {},
      onError: errors.add,
    );

    connectivity.incoming.add({
      'kind': 'bsharp.account',
      'version': 1,
      'school': 'osm-wroclaw',
    });
    await pumpEventQueue();

    expect(errors.single, isA<FormatException>());
    await subscription.cancel();
  });

  test('an account from a newer app version is reported', () async {
    final errors = <Object>[];
    final subscription = link.receivedAccounts.listen(
      (_) {},
      onError: errors.add,
    );
    final message = Map<String, dynamic>.of(
      encodeAccountHandoff(_account),
    )..['version'] = 99;

    connectivity.incoming.add(message);
    await pumpEventQueue();

    expect(errors.single, isA<UnsupportedHandoffVersion>());
    await subscription.cancel();
  });

  test('the phone says when Set up watch is open', () async {
    await link.announceSetupOpen();

    expect(connectivity.sent.single, {
      'kind': 'bsharp.setup-open',
      'version': 1,
    });
  });

  test('the watch hears that Set up watch opened on the phone', () async {
    final openings = <void>[];
    final subscription = link.setupOpenings.listen(openings.add);

    connectivity.incoming
      ..add({'kind': 'bsharp.account-received', 'version': 1})
      ..add({'kind': 'bsharp.setup-open', 'version': 1});
    await pumpEventQueue();

    expect(openings, hasLength(1));
    await subscription.cancel();
  });
}
