import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final wearCrownEventsProvider = StreamProvider<double>((ref) {
  const channel = EventChannel('pl.brothware.bsharp/rotary');
  return channel.receiveBroadcastStream().map((e) => (e as num).toDouble());
});
