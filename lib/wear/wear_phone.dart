import 'dart:async';

import 'package:bsharp/app/router.dart';
import 'package:bsharp/domain/watch_link.dart';
import 'package:bsharp/wear/wear_host_channel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Opens Set up watch in BSharp on the paired phone, so the wearer does not
/// have to find it. The watch keeps saying where it is either way, so a
/// phone that cannot be reached only costs that shortcut.
Future<bool> openSetUpWatchOnPhone() async {
  // Play services can sit on the request without ever answering, and the
  // wearer is waiting on this screen meanwhile.
  const answerTimeout = Duration(seconds: 10);
  try {
    return await wearHostChannel
            .invokeMethod<bool>('openOnPhone', {'url': watchSetupLink})
            .timeout(
              answerTimeout,
              onTimeout: () {
                debugPrint(
                  'openSetUpWatchOnPhone: no answer in $answerTimeout',
                );
                return false;
              },
            ) ??
        false;
  } on MissingPluginException {
    debugPrint('openSetUpWatchOnPhone: no host implementation');
    return false;
  } on PlatformException catch (error) {
    debugPrint('openSetUpWatchOnPhone: ${error.code} ${error.message}');
    return false;
  }
}

enum PhoneSetupOutcome { opened, notOpened, unreachable }

const _defaultOpenTimeout = Duration(seconds: 15);

class PhoneSetupOpener {
  PhoneSetupOpener(
    this._link, {
    this._openOnPhone = openSetUpWatchOnPhone,
    this._openTimeout = _defaultOpenTimeout,
  });

  final WatchLink _link;
  final Future<bool> Function() _openOnPhone;
  final Duration _openTimeout;
  StreamSubscription<void>? _openings;
  Timer? _deadline;
  int _attempt = 0;

  Future<void> open(ValueChanged<PhoneSetupOutcome> onOutcome) async {
    cancel();
    final attempt = _attempt;
    void report(PhoneSetupOutcome outcome) {
      if (attempt != _attempt) {
        return;
      }
      cancel();
      onOutcome(outcome);
    }

    _openings = _link.setupOpenings.listen(
      (_) => report(PhoneSetupOutcome.opened),
      onError: (Object error) =>
          debugPrint('PhoneSetupOpener: phone message unreadable: $error'),
    );
    final isDelivered = await _openOnPhone();
    if (attempt != _attempt) {
      return;
    }
    if (!isDelivered) {
      report(PhoneSetupOutcome.unreachable);
      return;
    }
    _deadline = Timer(
      _openTimeout,
      () => report(PhoneSetupOutcome.notOpened),
    );
  }

  void cancel() {
    _attempt++;
    _deadline?.cancel();
    _deadline = null;
    unawaited(_openings?.cancel());
    _openings = null;
  }
}
