import 'package:bsharp/domain/watch_open_permission.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _channel = MethodChannel('pl.brothware.bsharp/phone');

class PlatformWatchOpenPermission implements WatchOpenPermission {
  const PlatformWatchOpenPermission();

  @override
  Future<String?> connectedWatchName() async {
    try {
      return await _channel.invokeMethod<String>('connectedWatchName');
    } on MissingPluginException {
      debugPrint('PlatformWatchOpenPermission: no host implementation');
      return null;
    }
  }

  @override
  Future<void> openAppList() => _channel.invokeMethod<void>('openAppList');
}
