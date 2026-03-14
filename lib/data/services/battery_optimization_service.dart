import 'package:flutter/services.dart';

class BatteryOptimizationService {
  BatteryOptimizationService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('pl.brothware.bsharp/battery');

  final MethodChannel _channel;

  Future<bool> isExempt() async {
    final result = await _channel.invokeMethod<bool>('isExempt');
    return result ?? false;
  }

  Future<bool> requestExemption() async {
    final result = await _channel.invokeMethod<bool>('requestExemption');
    return result ?? false;
  }
}
