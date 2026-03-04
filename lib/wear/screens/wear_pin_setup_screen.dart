import 'package:bsharp/app/child_mode_provider.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/wear/widgets/wear_compact_keypad.dart';
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
    final theme = Theme.of(context);

    return Scaffold(
      body: WearSwipeDismiss(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 4),
              Text(
                _step == _PinSetupStep.create
                    ? t.childMode.createPin
                    : t.childMode.confirmPin,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pinLength, (i) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < _pin.length
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                    ),
                  );
                }),
              ),
              if (_error != null) ...[
                const SizedBox(height: 4),
                Text(
                  _error!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.error,
                    fontSize: 9,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Expanded(child: WearCompactKeypad(onKeyTap: _onKeyTap)),
            ],
          ),
        ),
      ),
    );
  }

  void _onKeyTap(String key) {
    HapticFeedback.lightImpact();

    if (key == 'del') {
      if (_pin.isNotEmpty) {
        setState(() => _pin = _pin.substring(0, _pin.length - 1));
      }
      return;
    }

    if (_pin.length >= _pinLength) return;

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
      ref.read(childModeProvider.notifier).setupPin(_pin);
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
