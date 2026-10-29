import 'package:bsharp/data/services/data_layer_watch_link.dart';
import 'package:bsharp/domain/watch_link.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:watch_connectivity/watch_connectivity.dart';

part 'watch_link_provider.g.dart';

@Riverpod(keepAlive: true)
WatchLink watchLink(Ref ref) => DataLayerWatchLink(WatchConnectivity());

@riverpod
Future<bool> hasPairedWatch(Ref ref) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return false;
  }
  try {
    return await ref.read(watchLinkProvider).hasPairedWatch();
  } on PlatformException catch (error) {
    debugPrint('hasPairedWatch: ${error.code} ${error.message}');
    return false;
  }
}
