import 'package:bsharp/data/services/tip_jar_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

const supportUrl = 'https://buymeacoffee.com/dawidsliwas';
const sourceCodeUrl = 'https://github.com/brothware/bsharp';

final packageInfoProvider = FutureProvider<PackageInfo>(
  (ref) => PackageInfo.fromPlatform(),
);

final isIosProvider = Provider<bool>((ref) {
  return !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
});

final tipJarServiceProvider = Provider<TipJarService?>((ref) {
  final isIos = ref.watch(isIosProvider);
  if (!isIos) return null;

  final service = TipJarService();
  ref.onDispose(service.dispose);
  return service;
});

final tipJarStateProvider = StreamProvider<TipJarState>((ref) {
  final service = ref.watch(tipJarServiceProvider);
  if (service == null) return const Stream.empty();
  return service.stateStream;
});
