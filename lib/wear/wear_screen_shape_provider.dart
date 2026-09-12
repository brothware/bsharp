import 'package:flutter/foundation.dart';
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
    const message =
        'wearScreenShapeProvider: MissingPluginException, '
        'falling back to rectangular';
    assert(false, message);
    debugPrint(message);
    return WearScreenShape.rectangular;
  }
}

class WearDisplay {
  const WearDisplay({required this.shape, required this.sizeDp});

  final WearScreenShape shape;
  final Size sizeDp;

  bool get isRound => shape == WearScreenShape.round;
  bool get isSmall => sizeDp.shortestSide < 225;
}
