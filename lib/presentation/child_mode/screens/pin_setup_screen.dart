import 'dart:async';

import 'package:bsharp/app/child_mode_provider.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/child_mode/widgets/pin_pad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  String? _firstPin;
  String? _error;
  final _padKey = GlobalKey<PinPadState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t.childMode.setupPinTitle)),
      body: Center(
        child: PinPad(
          key: _padKey,
          title: _firstPin == null
              ? t.childMode.createPin
              : t.childMode.confirmPin,
          errorMessage: _error,
          onComplete: _onPinEntered,
        ),
      ),
    );
  }

  Future<void> _onPinEntered(String pin) async {
    if (_firstPin == null) {
      setState(() {
        _firstPin = pin;
        _error = null;
      });
      _padKey.currentState?.clear();
      return;
    }

    if (pin != _firstPin) {
      setState(() => _error = t.childMode.pinMismatch);
      _padKey.currentState?.shake();
      setState(() => _firstPin = null);
      return;
    }

    final success = await ref.read(childModeProvider.notifier).setupPin(pin);
    if (success && mounted) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.childMode.pinSetSuccess)));
    }
  }
}
