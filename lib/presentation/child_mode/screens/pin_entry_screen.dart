import 'package:bsharp/app/child_mode_provider.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/child_mode/widgets/pin_pad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PinEntryScreen extends ConsumerStatefulWidget {
  const PinEntryScreen({super.key});

  @override
  ConsumerState<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends ConsumerState<PinEntryScreen> {
  String? _error;
  final _padKey = GlobalKey<PinPadState>();

  @override
  Widget build(BuildContext context) {
    final childModeState = ref.watch(childModeProvider);
    final theme = Theme.of(context);

    if (childModeState.isLocked) {
      return Scaffold(
        appBar: AppBar(title: Text(t.childMode.title)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_clock, size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                t.childMode.tooManyAttempts,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                t.childMode.tryAgainLater,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final remaining =
        ChildModeNotifier.maxAttempts - childModeState.failedAttempts;

    return Scaffold(
      appBar: AppBar(title: Text(t.childMode.title)),
      body: Center(
        child: PinPad(
          key: _padKey,
          title: t.childMode.enterParentPin,
          errorMessage:
              _error ??
              (childModeState.failedAttempts > 0
                  ? t.childMode.attemptsRemaining(remaining: remaining)
                  : null),
          onComplete: _onPinEntered,
        ),
      ),
    );
  }

  void _onPinEntered(String pin) {
    final success = ref.read(childModeProvider.notifier).exitChildMode(pin);
    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = t.childMode.invalidPin);
      _padKey.currentState?.shake();
    }
  }
}
