import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

abstract interface class BackgroundSyncScheduler {
  void schedule({required Duration interval});
  void cancel();
  bool get isScheduled;
}

const backgroundSyncTaskName = 'com.bsharp.backgroundSync';

class WorkmanagerSyncScheduler implements BackgroundSyncScheduler {
  bool _scheduled = false;

  @override
  bool get isScheduled => _scheduled;

  @override
  void schedule({required Duration interval}) {
    unawaited(
      Workmanager().registerPeriodicTask(
        backgroundSyncTaskName,
        backgroundSyncTaskName,
        frequency: interval,
        existingWorkPolicy: ExistingWorkPolicy.replace,
        constraints: Constraints(networkType: NetworkType.connected),
      ),
    );
    _scheduled = true;
  }

  @override
  void cancel() {
    unawaited(Workmanager().cancelByUniqueName(backgroundSyncTaskName));
    _scheduled = false;
  }
}

class WebSyncScheduler implements BackgroundSyncScheduler {
  WebSyncScheduler({required this.onSync});

  final Future<void> Function() onSync;
  Timer? _timer;
  bool isVisible = true;

  @override
  bool get isScheduled => _timer?.isActive ?? false;

  @override
  void schedule({required Duration interval}) {
    cancel();
    _timer = Timer.periodic(interval, (_) {
      if (isVisible) unawaited(onSync());
    });
  }

  @override
  void cancel() {
    _timer?.cancel();
    _timer = null;
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
