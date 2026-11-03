import 'dart:async';

import 'package:bsharp/domain/watch_link.dart';
import 'package:bsharp/wear/wear_phone.dart';
import 'package:flutter_test/flutter_test.dart';

const _openTimeout = Duration(milliseconds: 50);
const _pastTimeout = Duration(milliseconds: 120);

class _Link implements WatchLink {
  final openings = StreamController<void>.broadcast();

  @override
  Stream<void> get setupOpenings => openings.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Phone {
  final answer = Completer<bool>();
  int requests = 0;

  Future<bool> open() {
    requests++;
    return answer.future;
  }
}

void main() {
  late _Link link;
  late _Phone phone;
  late PhoneSetupOpener opener;
  late List<PhoneSetupOutcome> outcomes;

  setUp(() {
    link = _Link();
    phone = _Phone();
    opener = PhoneSetupOpener(
      link,
      openOnPhone: phone.open,
      openTimeout: _openTimeout,
    );
    outcomes = [];
  });

  tearDown(() {
    opener.cancel();
    return link.openings.close();
  });

  test('a phone that opens Set up watch reports it opened', () async {
    unawaited(opener.open(outcomes.add));
    phone.answer.complete(true);
    await pumpEventQueue();

    link.openings.add(null);
    await pumpEventQueue();

    expect(outcomes, [PhoneSetupOutcome.opened]);
    await Future<void>.delayed(_pastTimeout);
    expect(outcomes, [PhoneSetupOutcome.opened]);
  });

  test('a phone that takes the request but never opens says so', () async {
    unawaited(opener.open(outcomes.add));
    phone.answer.complete(true);
    await pumpEventQueue();
    expect(outcomes, isEmpty);

    await Future<void>.delayed(_pastTimeout);

    expect(outcomes, [PhoneSetupOutcome.notOpened]);
  });

  test('a phone that cannot be reached is reported at once', () async {
    unawaited(opener.open(outcomes.add));
    phone.answer.complete(false);
    await pumpEventQueue();

    expect(outcomes, [PhoneSetupOutcome.unreachable]);
    await Future<void>.delayed(_pastTimeout);
    expect(outcomes, [PhoneSetupOutcome.unreachable]);
  });

  test('an opening heard before the request is answered counts once', () async {
    unawaited(opener.open(outcomes.add));
    link.openings.add(null);
    await pumpEventQueue();
    phone.answer.complete(true);
    await Future<void>.delayed(_pastTimeout);

    expect(outcomes, [PhoneSetupOutcome.opened]);
  });

  test('a cancelled opening reports nothing', () async {
    unawaited(opener.open(outcomes.add));
    phone.answer.complete(true);
    await pumpEventQueue();

    opener.cancel();
    link.openings.add(null);
    await Future<void>.delayed(_pastTimeout);

    expect(outcomes, isEmpty);
  });

  test('opening again starts over', () async {
    unawaited(opener.open(outcomes.add));
    await pumpEventQueue();
    unawaited(opener.open(outcomes.add));
    phone.answer.complete(true);
    await pumpEventQueue();
    link.openings.add(null);
    await Future<void>.delayed(_pastTimeout);

    expect(outcomes, [PhoneSetupOutcome.opened]);
    expect(phone.requests, 2);
  });
}
