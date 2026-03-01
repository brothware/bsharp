import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum WearScreenShape { round, rectangular }

const _channel = MethodChannel('pl.brothware.bsharp/wear');

final wearScreenShapeProvider = FutureProvider<WearScreenShape>((ref) async {
  try {
    final isRound =
        await _channel.invokeMethod<bool>('isScreenRound') ?? false;
    return isRound ? WearScreenShape.round : WearScreenShape.rectangular;
  } on MissingPluginException {
    return WearScreenShape.rectangular;
  }
});

double wearListBottomInset(WearScreenShape shape) =>
    shape == WearScreenShape.round ? 32.0 : 0.0;
