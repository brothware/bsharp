import 'dart:async';

import 'package:flutter/foundation.dart';

abstract interface class BackgroundSyncScheduler {
  void schedule({required Duration interval});
  void cancel();
  bool get isScheduled;
}

class WebSyncScheduler implements BackgroundSyncScheduler {
  WebSyncScheduler({required this.onSync});

  final Future<void> Function() onSync;
  Timer? _timer;
  bool _isVisible = true;

  @override
  bool get isScheduled => _timer?.isActive ?? false;

  @override
  void schedule({required Duration interval}) {
    cancel();
    _timer = Timer.periodic(interval, (_) {
      if (_isVisible) onSync();
    });
  }

  @override
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void setVisibility({required bool visible}) {
    _isVisible = visible;
  }
}

class MobileSyncScheduler implements BackgroundSyncScheduler {
  MobileSyncScheduler({required this.onSync});

  final Future<void> Function() onSync;
  Duration? _interval;
  Timer? _timer;

  @override
  bool get isScheduled => _timer?.isActive ?? false;

  @override
  void schedule({required Duration interval}) {
    cancel();
    _interval = interval;
    _timer = Timer.periodic(interval, (_) => onSync());
  }

  @override
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void reschedule() {
    if (_interval != null) schedule(interval: _interval!);
  }
}

BackgroundSyncScheduler createScheduler({
  required Future<void> Function() onSync,
}) {
  if (kIsWeb) {
    return WebSyncScheduler(onSync: onSync);
  }
  return MobileSyncScheduler(onSync: onSync);
}
