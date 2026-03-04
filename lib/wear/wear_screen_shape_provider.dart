import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'wear_screen_shape_provider.g.dart';

enum WearScreenShape { round, rectangular }

const _channel = MethodChannel('pl.brothware.bsharp/wear');

@Riverpod(keepAlive: true)
Future<WearScreenShape> wearScreenShape(Ref ref) async {
  try {
    final isRound = await _channel.invokeMethod<bool>('isScreenRound') ?? false;
    return isRound ? WearScreenShape.round : WearScreenShape.rectangular;
  } on MissingPluginException {
    return WearScreenShape.rectangular;
  }
}

double wearListBottomInset(WearScreenShape shape) =>
    shape == WearScreenShape.round ? 32.0 : 0.0;
