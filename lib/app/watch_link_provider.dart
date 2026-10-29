import 'package:bsharp/data/services/data_layer_watch_link.dart';
import 'package:bsharp/domain/watch_link.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:watch_connectivity/watch_connectivity.dart';

part 'watch_link_provider.g.dart';

@Riverpod(keepAlive: true)
WatchLink watchLink(Ref ref) => DataLayerWatchLink(WatchConnectivity());
