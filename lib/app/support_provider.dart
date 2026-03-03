import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bsharp/data/services/tip_jar_service.dart';

const supportUrl = 'https://buymeacoffee.com/dawidsliwas';

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
