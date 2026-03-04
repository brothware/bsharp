import 'package:bsharp/data/services/tip_jar_service.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'support_provider.g.dart';

const supportUrl = 'https://buymeacoffee.com/dawidsliwas';
const sourceCodeUrl = 'https://github.com/brothware/bsharp';

@Riverpod(keepAlive: true)
Future<PackageInfo> packageInfo(Ref ref) => PackageInfo.fromPlatform();

@Riverpod(keepAlive: true)
bool isIos(Ref ref) {
  return !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
}

@Riverpod(keepAlive: true)
TipJarService? tipJarService(Ref ref) {
  final ios = ref.watch(isIosProvider);
  if (!ios) return null;

  final service = TipJarService();
  ref.onDispose(service.dispose);
  return service;
}

@Riverpod(keepAlive: true)
Stream<TipJarState> tipJarState(Ref ref) {
  final service = ref.watch(tipJarServiceProvider);
  if (service == null) return const Stream.empty();
  return service.stateStream;
}
