import 'package:bsharp/data/services/platform_watch_open_permission.dart';
import 'package:bsharp/domain/watch_open_permission.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_open_permission_provider.g.dart';

@Riverpod(keepAlive: true)
WatchOpenPermission watchOpenPermission(Ref ref) =>
    const PlatformWatchOpenPermission();

@riverpod
Future<String?> connectedWatchName(Ref ref) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return null;
  }
  try {
    return await ref.read(watchOpenPermissionProvider).connectedWatchName();
  } on PlatformException catch (error) {
    debugPrint('connectedWatchName: ${error.code} ${error.message}');
    return null;
  }
}
