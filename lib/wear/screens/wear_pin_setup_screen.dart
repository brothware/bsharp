import 'dart:async';

import 'package:bsharp/app/child_mode_provider.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:bsharp/wear/widgets/wear_pin_dial.dart';
import 'package:bsharp/wear/widgets/wear_swipe_dismiss.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _PinSetupStep { create, confirm }

class WearPinSetupScreen extends ConsumerStatefulWidget {
  const WearPinSetupScreen({super.key});

  @override
  ConsumerState<WearPinSetupScreen> createState() => _WearPinSetupScreenState();
}

class _WearPinSetupScreenState extends ConsumerState<WearPinSetupScreen> {
  String _pin = '';
  String? _firstPin;
  String? _error;
  _PinSetupStep _step = _PinSetupStep.create;
  static const _pinLength = 4;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WearSwipeDismiss(
        child: WearPinDial(
          shape: ref.watch(wearScreenShapeProvider).requireValue,
          prompt: _step == _PinSetupStep.create
              ? t.childMode.createPin
              : t.childMode.confirmPin,
          error: _error,
          enteredCount: _pin.length,
          pinLength: _pinLength,
          onKeyTap: _onKeyTap,
        ),
      ),
    );
  }

  void _onKeyTap(String key) {
    unawaited(HapticFeedback.lightImpact());

    if (key == WearPinDial.deleteKey) {
      if (_pin.isNotEmpty) {
        setState(() => _pin = _pin.substring(0, _pin.length - 1));
      }
      return;
    }

    if (_pin.length >= _pinLength) {
      return;
    }

    setState(() {
      _pin += key;
      _error = null;
    });

    if (_pin.length == _pinLength) {
      if (_step == _PinSetupStep.create) {
        setState(() {
          _firstPin = _pin;
          _pin = '';
          _step = _PinSetupStep.confirm;
        });
      } else {
        _confirmPin();
      }
    }
  }

  void _confirmPin() {
    if (_pin == _firstPin) {
      unawaited(ref.read(childModeProvider.notifier).setupPin(_pin));
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _error = t.childMode.pinMismatch;
        _pin = '';
        _firstPin = null;
        _step = _PinSetupStep.create;
      });
    }
  }
}
